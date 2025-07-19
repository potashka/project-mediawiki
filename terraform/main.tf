resource "yandex_vpc_network" "main" {
  name = "main-net"
}

resource "yandex_vpc_subnet" "main" {
  name           = "main-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_disk" "boot_disk" {
  for_each = var.virtual_machines

  name     = each.value.disk_name
  type     = "network-hdd"
  zone     = var.yc_zone
  size     = each.value.disk
  image_id = var.instance_image
}

resource "yandex_compute_instance" "vm" {
  for_each = var.virtual_machines

  name     = each.value.vm_name
  hostname = each.value.hostname

  resources {
    cores  = each.value.vm_cpu
    memory = each.value.ram
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot_disk[each.key].id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.instance_user}:${var.ssh_public_key}"
  }
}
