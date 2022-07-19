terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.14"
    }
  }
}

variable "domains" {
  type = map

  default = {
    control1 = {
      ip = "192.168.122.10"
    }
    worker1 = {
      ip = "192.168.122.20"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "iso-qcow2" {
  name   = "iso-qcow2"
  pool   = "default"
  source = "https://cloud.debian.org/cdimage/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"
  format = "qcow2"
}

resource "libvirt_volume" "disk_resized" {
  name           = "disk-${each.key}"
  base_volume_id = libvirt_volume.iso-qcow2.id
  pool           = "default"
  size           = 5361393152 * 4

  for_each = var.domains
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name           = "cloudinit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = "default"
}

resource "libvirt_domain" "domain" {
  name   = "machine-${each.key}"
  memory = "2048"
  vcpu   = 2

  for_each = var.domains
  cloudinit = libvirt_cloudinit_disk.cloudinit.id

  network_interface {
    network_name = "default"
    wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.disk_resized[each.key].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# output "ip1" {
#   value = libvirt_domain.domain["worker1"].network_interface[0].addresses[0]
# }

# output "ip" {
#   value = libvirt_domain.domain["control1"].network_interface[0].addresses[0]
# }
