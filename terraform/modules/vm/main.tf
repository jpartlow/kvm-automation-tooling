# Originally from: https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.8.1/examples/v0.13/ubuntu/ubuntu-example.tf

provider "libvirt" {
  uri = "qemu:///system"
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "volume-qcow2" {
  name   = "vm-image.${var.hostname}.qcow2"
  pool   = var.pool_name
  base_volume_name = var.base_volume_name
  base_volume_pool = default
  format = "qcow2"
  size   = var.disk_size # need to use cloud-init to grow the partition?
}

locals {
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
      bridge_ip = var.bridge_ip,
    }
  )
  meta_data = templatefile(
    "${local.cloud_init_path}/meta-data.yaml.tftpl",
    {
      hostname = var.hostname,
    }
  )
}

# for more info about parameters check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso.${var.hostname}"
  user_data      = locals.user_data
  network_config = locals.network_config
  meta_data      = locals.meta_data
  pool           = var.pool_name
}

# Create the machine
resource "libvirt_domain" "domain" {
  name   = "vm.${var.hostname}"
  memory = var.memory
  vcpu   = var.cpus

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
     bridge = "virbr0"
     # Should test with this enabled
     # wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.volume-qcow2.id
  }

  #  graphics {
  #    type        = "spice"
  #    listen_type = "address"
  #    autoport    = true
  #  }
}
