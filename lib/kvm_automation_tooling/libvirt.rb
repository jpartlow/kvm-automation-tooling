require 'libvirt'

module KvmAutomationTooling
  module Libvirt
    # https://gitlab.com/libvirt/libvirt-ruby/-/blob/master/examples/upload_volume.rb
    def upload_volume(file_path, volume_name, capacity = 3)
      with_libvirt do |lv|
        # define the XML that describes the new volume
        vol_xml = <<~EOF
          <volume>
            <name>#{volume_name}</name>
            <allocation unit="b">#{File.size(file_path)}</allocation>
            <capacity unit="G">#{capacity}</capacity>
          </volume>
        EOF
        # get a reference to the default storage pool
        pool = lv.lookup_storage_pool_by_name("default")
        # create the new volume in the storage pool
        volume = pool.create_volume_xml(vol_xml)
        # open up the original file
        image_file = File.open(file_path, "rb")
        # create a new stream to upload the data
        stream = lv.stream
        # start the upload, using the stream created above
        volume.upload(stream, 0, image_file.size)
        error = nil
        begin
          # send all of the data over the stream.  For each invocation of the
          # block, ruby-libvirt yields a tuple containing the opaque data passed
          # into sendall (here, nil), and the maximum number of bytes that it is
          # willing to accept right now.  The block should return a tuple, where
          # the first argument returns the number of bytes actually filled in
          # (up to a maximum of 'n', and with 0 meaning EOF), and the second
          # argument being the string containing the data to send.
          stream.sendall do |_opaque, n|
            begin
              r = image_file.read(n)
              r ? [0, r] : [0, ""]
            rescue Exception => e
              error = e
              [-1, ""]
            end
          end
  
          raise error if error
        ensure
          # once all of the data has been read by the block above, finish *must*
          # be called to ensure that all of it gets uploaded
          error.nil? ? stream.finish : stream.abort
        end
      end
    end
  
    def with_libvirt(&block)
      if @libvirt
        yield(@libvirt)
      else
        lv = Libvirt::open("qemu:///system")
        @libvirt = lv
        begin
          yield(@libvirt)
        ensure
          @libvirt = nil
          lv.close
        end
      end
    end
  
    def volume_exist?(volume_name)
      with_libvirt do |lv|
        pool = lv.lookup_storage_pool_by_name("default")
        pool.list_volumes.include?(volume_name)
      end
    end
  end
end
