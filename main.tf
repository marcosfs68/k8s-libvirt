resource "libvirt_network" "k8s_network" {
  name      = "k8s-network"
  mode      = "nat"
  domain    = "k8s.local"
  addresses = [var.cidr]
  autostart = true
}
#------------------------------------------------------------------------------
resource "libvirt_volume" "os_image" {
  name   = "os_image_debian"
  pool   = "VMs-nvme"
  source = "/var/lib/libvirt/images/debian-12-generic-amd64.qcow2"
  format = "qcow2"
}
#------------------------------------------------------------------------------
resource "libvirt_volume" "node_disk" {
  count  = var.node_count
  name   = "k8s-node-${count.index}-disk.qcow2"
  format = "qcow2"
  pool   = "VMs-nvme"
  base_volume_id = libvirt_volume.os_image.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "libvirt_cloudinit_disk" "node_cloudinit" {
  count  = var.node_count
  name   = "k8s-node-${count.index}-cloudinit.iso"
  pool   = "VMs-nvme"
  user_data = templatefile("cloud-config.yaml", {
    ssh_authorized_keys = var.ssh_public_key
    hostname       = "k8s-node-${count.index}"
    worker_ip_list = join(" ", slice(local.node_ips, 2, var.node_count+1))
    is_manager     = count.index == 0
    node_ip        = local.node_ips[count.index+1]
    nodes          = var.node_count
  })
}

resource "libvirt_domain" "k8s_node" {
  count  = var.node_count
  name   = "k8s-node-${count.index}"
  memory = var.node_memory
  vcpu   = var.node_vcpu
  autostart = true
  qemu_agent = true
  network_interface {
    network_id     = libvirt_network.k8s_network.id
    addresses      = [local.node_ips[count.index+1]]
  }
  disk {
    volume_id = libvirt_volume.node_disk[count.index].id
  }
  boot_device {
    dev = ["hd"]
  }
  cloudinit = libvirt_cloudinit_disk.node_cloudinit[count.index].id
}
#------------------------------------------------------------------------------
resource "libvirt_volume" "node_support_disk" {
  name   = "k8s-node-support-disk"
  base_volume_id = libvirt_volume.os_image.id
  format = "qcow2"
  pool   = "VMs-nvme"

  lifecycle {
    create_before_destroy = true
  }
}

resource "libvirt_cloudinit_disk" "node_support" {
  name     = "k8s-node-support-cloudinit.iso"
  pool   = "VMs-nvme"
  user_data = templatefile("cloud-config-support.yaml", {
    ssh_authorized_keys = var.ssh_public_key
    hostname            = "k8s-support"
  })
}

resource "libvirt_domain" "k8s_support" {
  name   = "k8s-support"
  memory = var.node_memory
  vcpu   = var.node_vcpu
  qemu_agent = true
  network_interface {
    network_id     = libvirt_network.k8s_network.id
    addresses      = [local.node_ips[0]]
  }
  disk {
    volume_id = libvirt_volume.node_support_disk.id
  }
  boot_device {
    dev = ["hd"]
  }
  cloudinit = libvirt_cloudinit_disk.node_support.id
}
