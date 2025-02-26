#! /usr/bin/env ruby

require_relative "../../ruby_task_helper/files/task_helper.rb"
require_relative "../lib/kvm_automation_tooling/libvirt.rb"

class ImportLibvirtVolume < TaskHelper
  include KvmAutomationTooling::Libvirt

  def task(image_path:, volume_name:, **kwargs)
    with_libvirt do
      if !volume_exist?(volume_name)
        upload_volume(volume_name, image_path)
      end
    end
  end
end

ImportLibvirtVolume.run if __FILE__ == $0
