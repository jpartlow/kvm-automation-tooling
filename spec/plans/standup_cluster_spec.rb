require 'spec_helper'

describe 'plan: standup_cluster' do
  include_context 'plan_init'

  let(:params) do
    {
      'cluster_name' => 'test_cluster',
      'os' => 'ubuntu',
      'os_version' => '24.04',
      'os_arch' => 'x86_64',
    }
  end
require 'pry-byebug'
  it 'should run successfully' do
    expect_task('kvm_automation_tooling::download_image')
    expect_task('kvm_automation_tooling::import_libvirt_volume')
    expect_task('kvm_automation_tooling::create_libvirt_image_pool')

    result = run_plan('kvm_automation_tooling::standup_cluster', params)
    expect(result.ok?).to(eq(true), result.value)
  end
end
