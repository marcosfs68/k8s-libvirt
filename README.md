# k8s-libvirt

K8S deployed in libvirtd

Terraform modules:

- [https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs]

OBS: O terraform precisa estar atualizado

Como a versão do módulo libvirt não suporta cdrom como virtio, somente IDE, o boot apresenta crash no kernel, então vamos ajustar o disco manualmente para usar

```bash
cd /var/lib/libvirt/images/
F=debian-12-generic-amd64.qcow2
wget https://cloud.debian.org/images/cloud/bookworm/latest/$F

qemu-img info $F
qemu-img resize $F 30G
qemu-img info $F
sudo modprobe nbd max_part=10
sudo qemu-nbd -c /dev/nbd0 $F
sudo fdisk -l /dev/nbd0
sudo growpart /dev/nbd0 1
sudo fdisk -l /dev/nbd0
sudo resize2fs /dev/nbd0p1
sudo qemu-nbd -d /dev/nbd0
sudo modprobe -r nbd
```
