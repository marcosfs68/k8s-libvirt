locals {
  node_ips = [
    # This will be generate IPs address for nodes.
    # First IP of CIDR will be for IP support node and the other ones will be for k8s nodes
    # Then it starts generating with second IP of ccidr.
    # 192.168.123.1 -> gateway
    # 192.168.123.2 -> node_support
    for i in range(var.node_count+1) : cidrhost(var.cidr, i + var.node_count - 1)
  ]  
}
