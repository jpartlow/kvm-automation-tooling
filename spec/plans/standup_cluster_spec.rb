require 'spec_helper'
require 'tmpdir'

describe 'plan: standup_cluster' do
  include_context 'plan_init'

  let(:terraform_state_dir) { Dir.mktmpdir('rspec-kat-terraform-state') }
  let(:params) do
    {
      'cluster_name' => 'spec',
      'os'           => 'ubuntu',
      'os_version'   => '24.04',
      'os_arch'      => 'x86_64',
      'terraform_state_dir' => terraform_state_dir,
    }
  end
  let(:cluster_id) { 'spec-singular-ubuntu-2404-amd64' }

  around(:each) do |example|
    example.run
  ensure
    FileUtils.remove_entry_secure(terraform_state_dir)
  end

  it 'should run successfully' do
    expect_task('kvm_automation_tooling::download_image')
    expect_task('kvm_automation_tooling::import_libvirt_volume')
    expect_task('kvm_automation_tooling::create_libvirt_image_pool')
    expect_task('terraform::initialize')
    expect_task('terraform::apply')
      .with_targets('localhost')
      .with_params(
        'dir'       => './terraform',
        'state'     => "#{terraform_state_dir}/#{cluster_id}.tfstate",
        'state_out' => nil,
        'target'    => nil,
        'var'       => nil,
        'var_file'  => "#{terraform_state_dir}/#{cluster_id}.tfvars.json",
      )

    result = run_plan('kvm_automation_tooling::standup_cluster', params)
    puts %x[ls -l #{terraform_state_dir}]
    expect(result.ok?).to(eq(true), result.value)
  end
end
