variable "yc_cloud_id" {}
variable "yc_folder_id" {}
variable "yc_zone" {}
variable "instance_image" {}
variable "ssh_public_key" {}
variable "instance_user" {}
variable "service_account_key_file" {}

variable "virtual_machines" {
  type = map(object({
    vm_name   = string
    hostname  = string
    vm_cpu    = number
    ram       = number
    disk      = number
    disk_name = string
    role      = string
  }))
}