resource "random_id" "id" {
    byte_length = 4
    prefix      = var.project
}

resource "google_project" "project" {
    name       = var.project
    project_id = random_id.id.hex
    auto_create_network = false
    billing_account = var.billing_acccount
}

resource "google_project_service" "gke-api" {
    project = google_project.project.project_id
    service = "container.googleapis.com"
}

resource "google_compute_network" "vpc" {
    name                    = "${var.project}-vpc"
    auto_create_subnetworks = "false"
    project = google_project.project.project_id
}

resource "google_compute_subnetwork" "private-subnet" {
    name          = "${var.project}-private-subnet"
    ip_cidr_range = "10.0.0.0/24"
    network       = google_compute_network.vpc.name
    depends_on    = [google_compute_network.vpc]
    region        = var.location
    private_ip_google_access = "true"
    project = google_project.project.project_id
}

resource "google_compute_router" "router" {
    name    = "${var.project}-router"
    project = google_project.project.project_id
    region  = var.location
    network = google_compute_network.vpc.self_link

    bgp {
        asn = 64514
    }
}

resource "google_compute_router_nat" "nat" {
    name                               = "${var.project}-router-nat"
    router                             = google_compute_router.router.name
    region                             = google_compute_router.router.region
    nat_ip_allocate_option             = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
    project = google_project.project.project_id

    log_config {
        enable = true
        filter = "ERRORS_ONLY"
    }
}

resource "google_container_cluster" "primary" {
    name     = "${var.project}-gke-cluster"
    location = var.zone

    # We can't create a cluster with no node pool defined, but we want to only use
    # separately managed node pools. So we create the smallest possible default
    # node pool and immediately delete it.
    remove_default_node_pool = true
    initial_node_count       = 1

    project = google_project.project.project_id

    ip_allocation_policy {
        # Whether alias IPs will be used for pod IPs in the cluster. Defaults to
        # true if the ip_allocation_policy block is defined, and to the API
        # default otherwise. Prior to June 17th 2019, the default on the API is
        # false; afterwards, it's true.
    }

    private_cluster_config {
        # Whether the master's internal IP address is used as the cluster endpoint.
        enable_private_endpoint = false

        # Whether nodes have internal IP addresses only. If enabled, all nodes are
        # given only RFC 1918 private addresses and communicate with the master via
        # private networking.
        enable_private_nodes = true
        master_ipv4_cidr_block = "10.0.1.0/28"
    }

    network = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.private-subnet.id

    master_auth {
        username = ""
        password = ""

        client_certificate_config {
            issue_client_certificate = false
        }
    }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
    name       = "${var.project}-node-pool"
    cluster    = google_container_cluster.primary.name
    node_count = 2

    location = var.zone
    project = google_project.project.project_id

    node_config {
        preemptible  = true
        machine_type = "n1-standard-1"
        metadata = {
            disable-legacy-endpoints = "true"
        }

        oauth_scopes = [
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring",
        ]
    }
}
