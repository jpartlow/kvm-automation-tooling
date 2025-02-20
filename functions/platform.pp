# Generic function to produce a cononical descriptive platform string from a
# set of os, version and cpu arch values.
function kvm_automation_tooling::platform(
  Kvm_automation_tooling::Operating_systems $os,
  Kvm_automation_tooling::Version $version,
  Kvm_automation_tooling::Os_arch $arch,
) {
  case $os {
    'ubuntu': {
      $_version = regsubst($version, '[._]', '', 'G')
      $_arch = $arch ? {
        'x86_64'  => 'amd64',
        'aarch64' => 'arm64',
        default   => $arch,
      }
      "${os}-${_version}-${_arch}"
    }
    default: {
      fail("TODO: Implement support for operating system: ${os}")
    }
  }
}
