variable "debian_domains" {
  type = map

  default = {
    debian1 = {
      ip = "192.168.122.10"
      worker = false
    },
    debian3 = {
      ip = "192.168.122.15"
      worker = true
    }
  }
}

variable "debian2_domains" {
  type = map

  default = {
    debian2 = {
      ip = "192.168.122.20"
      worker = false
    }
  }
}

variable "ubuntu_domains" {
  type = map

  default = {
    ubuntu1 = {
      ip = "192.168.122.50"
      worker = false
    }
  }
}

module "debian1" {
  source = "./modules/k8s-cluster"
  cluster_name = "debian1"
  iso_url = "https://cloud.debian.org/cdimage/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"
  template_file = "${path.module}/cloud_init.cfg"
  domains = var.debian_domains
}

# module "debian2" {
#   source = "./modules/k8s-cluster"
#   cluster_name = "debian2"
#   iso_url = "https://cloud.debian.org/cdimage/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"
#   template_file = "${path.module}/cloud_init.cfg"
#   domains = var.debian2_domains
# }

# module "ubuntu" {
#   source = "./modules/k8s-cluster"
#   cluster_name = "ubuntu"
#   iso_url = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
#   template_file = "${path.module}/cloud_init_ubuntu.cfg"
#   domains = var.ubuntu_domains
# }
