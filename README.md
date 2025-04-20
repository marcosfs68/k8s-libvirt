# k8s-libvirt
K8S deployed in libvirtd

wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

F=debian-12-generic-amd64.qcow2
qemu-img info $F
qemu-img resize $F 30G

sudo modprobe nbd max_part=10
sudo qemu-nbd -c /dev/nbd0 $F
sudo growpart /dev/nbd0 1
sudo resize2fs /dev/nbd0p1
sudo qemu-nbd -d /dev/nbd0
sudo modprobe -r nbd

