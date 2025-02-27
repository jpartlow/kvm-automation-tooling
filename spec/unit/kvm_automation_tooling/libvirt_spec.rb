require 'spec_helper'

require 'kvm_automation_tooling/libvirt'

class LibvirtTest
  # Specs manipulating the local libvirt environment are unexpected.  To
  # run these specs, set the RUN_KVM_AUTOMATION_TOOLING_LIBVIRT_SPECS
  # environment variable.
  RUN_LIBVIRT_SPECS = ENV['RUN_KVM_AUTOMATION_TOOLING_LIBVIRT_SPECS']

  def self.libvirt_available?
    RUN_LIBVIRT_SPECS && Libvirt::open("qemu:///system")
  rescue
    false
  end
end

describe KvmAutomationTooling::LibvirtWrapper, if: LibvirtTest.libvirt_available? do
  let(:libvirt) { Libvirt::open("qemu:///system") }
  let(:pool) { libvirt.lookup_storage_pool_by_name("default") }
  let(:volumes) { pool.list_volumes }

  describe 'Client' do
    let(:client) { KvmAutomationTooling::LibvirtWrapper::Client.new }
  
    describe '#upload_volume' do
      let(:test_volume_name) { 'kvm-automation-tooling-spec-test-volume' }
      let(:test_image) { '/tmp/kvm-automation-tooling-spec-test-volume.img' }
  
      around(:each) do |example|
        File.write(test_image, 'test')
        example.run
      ensure
        File.delete(test_image) if File.exist?(test_image)
        vol = pool.lookup_volume_by_name(test_volume_name)
        vol.delete if vol
      end
  
      it 'uploads a volume' do
        expect(client.volume_exist?(test_volume_name)).to eq(false)
        expect(client.upload_volume(test_image, test_volume_name)).to eq(true)
        expect(client.volume_exist?(test_volume_name)).to eq(true)
      end
    end
  
    describe '#volume_exist?' do
      it 'returns true if the volume exists' do
        expect(client.volume_exist?(volumes.first)).to eq(true)
      end
  
      it 'returns false if the volume does not exist' do
        expect(client.volume_exist?('a-thousand-dingos')).to eq(false)
      end
    end

    describe '#pool_exist?' do
      it 'returns true if the pool exists' do
        expect(client.pool_exist?('default')).to eq(true)
      end

      it 'returns false if the pool does not exist' do
        expect(client.pool_exist?('two-thousand-dingos')).to eq(false)
      end
    end

    describe '#create_pool' do
      let(:test_pool_name) { 'kvm-automation-tooling-spec-test-pool' }
  
      around(:each) do |example|
        example.run
      ensure
        begin
          test_pool = libvirt.lookup_storage_pool_by_name(test_pool_name)
          test_pool.destroy
          test_pool.delete
          test_pool.undefine
        rescue Libvirt::RetrieveError
          # Thrown by lookup_storage_pool_by_name if the pool does not
          # exist...
        end
      end
  
      it 'creates a pool' do
        expect(client.pool_exist?(test_pool_name)).to eq(false)
        expect(client.create_pool(test_pool_name)).to eq(true)
        expect(client.pool_exist?(test_pool_name)).to eq(true)
        pool = libvirt.lookup_storage_pool_by_name(test_pool_name)
        expect(pool.active?).to eq(true)
        expect(pool.autostart).to eq(true)
      end
    end
  end

  describe '#with_libvirt' do
    class Tester
      include KvmAutomationTooling::LibvirtWrapper
    end

    let(:tester) { Tester.new }

    it 'yields a Client instance with a libvirt connection' do
      c = nil
      tester.with_libvirt do |client|
        expect(client.volume_exist?(volumes.first)).to eq(true)
        c = client
      end
      expect(c.lv).to be_closed
    end
  end
end
