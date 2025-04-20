terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  nodes = 3
  cidr = "192.168.123.0/24"
  node_ips = [
    for i in range(local.nodes) : cidrhost(local.cidr, i + local.nodes + 1)
  ]  
}

variable "node_count" {
  description = "Number of Kubernetes nodes"
  type        = number
  default     = local.nodes
}

variable "node_memory" {
  description = "Memory per Kubernetes node (in MB)"
  type        = number
  default     = 4096
}

variable "node_vcpu" {
  description = "vCPUs per Kubernetes node"
  type        = number
  default     = 2
}

variable "node_disk_size_gb" {
  description = "Disk size per Kubernetes node (in GB)"
  type        = number
  default     = 20
}

variable "ssh_public_key" {
  description = "SSH public key for accessing nodes"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWospR7cUn7KRPUIwhepo0ZEbUXV13SqtbNuVmaVRLJXmlkI3ypH82jP7knTs7S92mZMRf7TM0MR+iH8ui84/kL4qpeRMU6n+05ciEjEQ1VyPUHcua9t8CvLrdJKUIXwAssSYl6Qn8NLmwh/fq0Cjo+dVenTdtXcmlgT3kfTV58Td5WwmRVazMERirpccx/Jfb7i1Onsvqb2z2ZrpwdVpj6oHh8/KI0+Qei/Y5Tf6VHGp2hA01YfXqVnMUQx6zQhRGCGqAXh76PYbTcwYXQXzuufhs6QpmKjlCjVvLAyyNiNkdMopUqGVboWij457BK5tKpBJkM+ntghPYu9NwClhv Chave Teste"
}

resource "libvirt_network" "k8s_network" {
  name      = "k8s-network"
  mode      = "nat"
  domain    = "k8s.local"
  addresses = [local.cidr]
}
#------------------------------------------------------------------------------
resource "libvirt_volume" "node_disk" {
  count  = var.node_count
  name   = "node-${count.index}-disk"
  source = "node-${count.index}-disk.qcow2"
  format = "qcow2"
  pool   = "VMs-nvme"
  depends_on = [
    null_resource.clone_and_resize_disk
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "libvirt_cloudinit_disk" "node_cloudinit" {
  count    = var.node_count
  name     = "node-${count.index}-cloudinit.iso"
  pool   = "VMs-nvme"
  user_data = templatefile("cloud-config.yaml", {
    ssh_authorized_keys = var.ssh_public_key
    hostname            = "k8s-node-${count.index}"
    worker_ip_list      = local.node_ips
    is_manager          = count.index == 0
  })
}

resource "libvirt_domain" "k8s_node" {
  count  = var.node_count
  name   = "k8s-node-${count.index}"
  memory = var.node_memory
  vcpu   = var.node_vcpu
  network_interface {
    network_id     = libvirt_network.k8s_network.id
    wait_for_lease = true
  }
  disk {
    volume_id = libvirt_volume.node_disk[count.index].id
  }
  boot_device {
    dev = ["hd"]
  }
  cloudinit {
    disk_id = libvirt_cloudinit_disk.node_cloudinit[count.index].id
    network_config_id = libvirt_cloudinit_disk.node_cloudinit[count.index].id # You might need a separate network config
  }
  cpu {
    mode = "host-model"
  }
}

output "node_ips" {
  value = [for node in libvirt_domain.k8s_node : node.network_interface[0].addresses[0]]
}
#------------------------------------------------------------------------------
resource "libvirt_volume" "node_disk" {
  name   = "node-support-disk"
  source = "node-support-disk.qcow2"
  format = "qcow2"
  pool   = "VMs-nvme"
  depends_on = [
    null_resource.clone_and_resize_disk
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "libvirt_cloudinit_disk" "node_cloudinit" {
  count    = var.node_count
  name     = "node-${count.index}-cloudinit.iso"
  pool   = "VMs-nvme"
  user_data = templatefile("cloud-config-support.yaml", {
    ssh_authorized_keys = var.ssh_public_key
    hostname            = "k8s-support"
  })
}

resource "libvirt_domain" "k8s_node" {
  name   = "k8s-support"
  memory = var.node_memory
  vcpu   = var.node_vcpu
  network_interface {
    network_id     = libvirt_network.k8s_network.id
    wait_for_lease = true
  }
  disk {
    volume_id = libvirt_volume.node_disk[count.index].id
  }
  boot_device {
    dev = ["hd"]
  }
  cloudinit {
    disk_id = libvirt_cloudinit_disk.node_cloudinit[count.index].id
    network_config_id = libvirt_cloudinit_disk.node_cloudinit[count.index].id # You might need a separate network config
  }
  cpu {
    mode = "host-model"
  }
}
