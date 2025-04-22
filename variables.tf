variable "node_count" {
  description = "Number of Kubernetes nodes"
  type        = number
  default     = 3
}

variable "node_memory" {
  description = "Memory per Kubernetes node (in MB)"
  type        = number
  default     = 5120
}

variable "node_vcpu" {
  description = "vCPUs per Kubernetes node"
  type        = number
  default     = 2
}

variable "ssh_public_key" {
  description = "SSH public key for accessing nodes"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWospR7cUn7KRPUIwhepo0ZEbUXV13SqtbNuVmaVRLJXmlkI3ypH82jP7knTs7S92mZMRf7TM0MR+iH8ui84/kL4qpeRMU6n+05ciEjEQ1VyPUHcua9t8CvLrdJKUIXwAssSYl6Qn8NLmwh/fq0Cjo+dVenTdtXcmlgT3kfTV58Td5WwmRVazMERirpccx/Jfb7i1Onsvqb2z2ZrpwdVpj6oHh8/KI0+Qei/Y5Tf6VHGp2hA01YfXqVnMUQx6zQhRGCGqAXh76PYbTcwYXQXzuufhs6QpmKjlCjVvLAyyNiNkdMopUqGVboWij457BK5tKpBJkM+ntghPYu9NwClhv Chave Teste"
}

variable "cidr" {
  type = string
  default = "192.168.123.0/24"
}

variable "support_enabled" {
  type = bool
  default = false
}