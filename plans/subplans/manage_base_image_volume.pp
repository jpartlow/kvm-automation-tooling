plan kvm_automation_tooling::subplans::manage_base_image_volume(
  String $platform,
  String $image_download_dir,
) {

  # Download and import base image.
  $base_volume_name = "${platform}.qcow2"
  $base_image_url = kvm_automation_tooling::get_image_url($platform)
  $base_image_name = $base_image_url.split('/')[-1]
  $base_image_path = "${image_download_dir}/${base_image_name}"
  run_task('kvm_automation_tooling::download_image', 'localhost',
    'image_url'    => $base_image_url,
    'download_dir' => $image_download_dir,
  )
  run_task('kvm_automation_tooling::import_libvirt_volume', 'localhost',
    'image_path'  => $base_image_path,
    'volume_name' => $base_volume_name,
  )

  # Ensure platform image pool exists.
  run_task('kvm_automation_tooling::create_libvirt_image_pool', 'localhost',
    'name' => $platform,
  )
}
