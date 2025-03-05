locals {
  identifier = "${var.cluster_id}-${var.hostname}"
  fqdn = "${var.hostname}.${var.domain_name}"

  # The path to the cloud-init configuration templates
  cloud_init_path = "${path.module}/../../../cloud-init"
  user_data = templatefile(
    "${local.cloud_init_path}/user-data.yaml.tftpl",
    {
      ssh_authorized_key = var.ssh_public_key,
      user_password      = var.user_password,
    }
  )
  network_config = templatefile(
    "${local.cloud_init_path}/network-config.yaml.tftpl",
    {
      gateway_ip = var.gateway_ip
    }
  )
  meta_data = templatefile(
    "${local.cloud_init_path}/meta-data.yaml.tftpl",
    {
      hostname = var.hostname,
    }
  )
  gigabyte = 1024 * 1024 * 1024
}
