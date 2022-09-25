
Repo to experiment with a kubernetes cluster using kubeadm

- [terraform-provider-libvirt](https://github.com/dmacvicar/terraform-provider-libvirt) to setup the virtual machines
- cloud-init to bootstrap the initial configuration
- terraform remote-exec for subsequent kubeadm commands

# Run

``` shell
terraform init
terraform apply

# To login to control plane
# Get SSH public key from ssh_public_key variable
# Default to ~/.ssh/id_ed25519.pub
# IP defined in main.tf
ssh kubernetes@192.168.122.10
```

