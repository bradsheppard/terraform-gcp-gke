# Terraform GCP GKE

This repository contains terraform scripts which bootstrap a GKE managed Kubernetes cluster into GCP, along with
an associated project, and basic networking. The cluster worker nodes are on a private subnet, however the 
master control plane is publicly accessible. 

## Requirements

- GCP account with sufficient privileges.
- Terraform in a semi-modern state.

## Usage

Before running a `terraform apply` please ensure that the appropriate variables are set in `variables.tf`.
You will also need to ensure that the `provider.google` and `provider.random` plugins are installed. To achieve
this, run

```
terraform init
```

This will create a `.terraform` directory containing the plugin files.

It may also be necessary to install the GCP command line tool, `gcloud`, and login using

```
gcloud auth login
```

You should now be able to run
```
terraform apply
```

to begin the deployment. Note that the deployment can take quite some time, as the `google_container_cluster` resource
takes quite a while to provision.




