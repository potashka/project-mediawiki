output "external_ips" {
  value = {
    for key, inst in yandex_compute_instance.vm :
    key => inst.network_interface[0].nat_ip_address
  }
}

output "internal_ips" {
  value = {
    for key, inst in yandex_compute_instance.vm :
    key => inst.network_interface[0].ip_address
  }
}
