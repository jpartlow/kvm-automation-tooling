require 'spec_helper'

require_relative '../../tasks/import_libvirt_volume'

class LibvirtTest
  # Specs manipulating the local libvirt environment are unexpected.
  # To run these specs, set the RUN_KVM_AUTOMATION_TOOLING_LIBVIRT_SPECS environment variable.
  RUN_LIBVIRT_SPECS = ENV['RUN_KVM_AUTOMATION_TOOLING_LIBVIRT_SPECS']

  def self.libvirt_available?
    RUN_LIBVIRT_SPECS && Libvirt::open("qemu:///system")
  rescue
    false
  end
end

describe 'task: import_libvirt_volume.rb', if: LibvirtTest.libvirt_available? do
  let(:libvirt) { Libvirt::open("qemu:///system") }
  let(:pool) { libvirt.lookup_storage_pool_by_name("default") }
  let(:volumes) { pool.list_volumes }
  let(:task) { ImportLibvirtVolume.new }

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
      expect(task.volume_exist?(test_volume_name)).to eq(false)
      expect(task.upload_volume(test_image, test_volume_name)).to be_nil
      expect(task.volume_exist?(test_volume_name)).to eq(true)
    end
  end

  describe '#volume_exist?' do
    it 'returns true if the volume exists' do
      expect(task.volume_exist?(volumes.first)).to eq(true)
    end

    it 'returns false if the volume does not exist' do
      expect(task.volume_exist?('a-thousand-dingos')).to eq(false)
    end
  end
end
