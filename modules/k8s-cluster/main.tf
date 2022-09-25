terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.14"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "iso-qcow2" {
  name   = "qcow2-${var.cluster_name}.iso"
  pool   = "default"
  format = "qcow2"
  source = var.iso_url
}

resource "libvirt_volume" "disk_resized" {
  name           = "disk-${each.key}.iso"
  base_volume_id = libvirt_volume.iso-qcow2.id
  pool           = "default"
  size           = 5361393152 * 4

  for_each = var.domains
}

data "template_file" "user_data" {
  template = file(var.template_file)

  vars = {
    hostname = each.key
    public_key = var.ssh_public_key != null ? var.ssh_public_key : file(pathexpand("~/.ssh/id_ed25519.pub"))
  }

  for_each = var.domains
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")

  vars = {
    ip = each.value.ip
  }

  for_each = var.domains
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name           = "cloudinit-${each.key}.iso"
  user_data      = data.template_file.user_data[each.key].rendered
  network_config = data.template_file.network_config[each.key].rendered
  pool           = "default"

  for_each = var.domains
}

resource "libvirt_domain" "domain" {
  name   = "machine-${each.key}"
  memory = "4096"
  vcpu   = 2

  for_each = var.domains
  cloudinit = libvirt_cloudinit_disk.cloudinit[each.key].id

  network_interface {
    network_name = "default"
  }

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

  provisioner "remote-exec" {
    connection {
      host        = each.value.ip
      type        = "ssh"
      user        = "kubernetes"
      private_key =  var.ssh_private_key != null ? var.ssh_private_key : file(pathexpand("~/.ssh/id_ed25519"))
    }

    # Copied from kubitect
    inline = [
      "while ! sudo grep \"Cloud-init .* finished\" /var/log/cloud-init.log; do echo \"Waiting for cloud-init to finish...\"; sleep 2; done"
    ]
  }
}

resource "null_resource" "kubeadm_init" {
  triggers = {
    domain_id = libvirt_domain.domain[each.key].id
  }

  provisioner "remote-exec" {
    when    = create

    connection {
      host        = each.value.ip
      type        = "ssh"
      user        = "kubernetes"
      private_key =  var.ssh_private_key != null ? var.ssh_private_key : file(pathexpand("~/.ssh/id_ed25519"))
    }

    inline = [
      "sudo kubeadm init --service-cidr \"10.96.0.0/12\" --pod-network-cidr \"10.244.0.0/16\" --token wkfvbq.d1dioz5bwjxwtxuz"
    ]
  }

  for_each = { for key, val in var.domains: key => val if !val.worker }
}
