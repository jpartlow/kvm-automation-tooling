require 'spec_helper'

describe 'plan: teardown_cluster' do
  include_context 'plan_init'

  let(:params) do
    {
      'cluster_id' => 'spec-singular-ubuntu-2404-amd64',
    }
  end
  let(:terraform_state_dir) do
    File.join(KatRspec.fixture_path, 'modules/kvm_automation_tooling/files/../terraform/instances')
  end

  it 'should run successfully' do
    expect_task('terraform::destroy')
      .with_targets('localhost')
      .with_params(
        'dir'       => './terraform',
        'state'     => "#{terraform_state_dir}/#{params['cluster_id']}.tfstate",
        'state_out' => nil,
        'target'    => nil,
        'var'       => nil,
        'var_file'  => "#{terraform_state_dir}/#{params['cluster_id']}.tfvars.json",
      )

    pp terraform_state_dir
    result = run_plan('kvm_automation_tooling::teardown_cluster', params)
    expect(result.ok?).to(eq(true), result.value)
  end
end
