output "node_ips" {
  value = [for node in libvirt_domain.k8s_node : node.network_interface[0].addresses[0]]
}

output "support_ip" {
  value = [for node in libvirt_domain.k8s_support : node.network_interface[0].addresses[0]]
}