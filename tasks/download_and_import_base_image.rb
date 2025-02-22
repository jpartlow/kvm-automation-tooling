#! /usr/bin/env ruby

require_relative "../../ruby_task_helper/files/task_helper.rb"

class DownloadAndImportBaseImage < TaskHelper

  # https://gitlab.com/libvirt/libvirt-ruby/-/blob/master/examples/upload_volume.rb
  def upload_volume(file_path)
    # TODO break this up into something sensible

    # open up a connection to the qemu driver
    c = Libvirt::open("qemu:///system")
    # define the XML that describes the new volume
    vol_xml = <<~EOF
      <volume>
        <name>#{File.basename(file_path)}</name>
        <allocation unit="G">0</allocation>
        <capacity unit="b">#{File.size(file_path)}</capacity>
      </volume>
    EOF
    # get a reference to the default storage pool
    pool = c.lookup_storage_pool_by_name("default")
    # create the new volume in the storage pool
    volume = pool.create_volume_xml(vol_xml)
    # create a new stream to upload the data
    stream = c.stream
    # open up the original file
    image_file = File.open(file_path, "rb")
    # start the upload, using the stream created above
    volume.upload(stream, 0, image_file.size)
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
        # TODO: need to pick one of these, I assume
        # This works with and without 03f18670c79e6664fb424d6731f95ea2be4531f4
        r ? [r.length, r] : [0, ""]
        # This works with 03f18670c79e6664fb424d6731f95ea2be4531f4 and matches the
        # docs
        r ? [0, r] : [0, ""]
      rescue Exception => e
        $stderr.puts "Got exception #{e}"
        [-1, ""]
      end
    end
    # once all of the data has been read by the block above, finish *must*
    # be called to ensure that all of it gets uploaded
    stream.finish
    c.close
  end

  def task(name: nil, **kwargs)
#image_url=$PT_image_url
#download_dir=$PT_download_dir
#volume_name=$PT_volume_name
#
#image_name=${image_url##*/}
#image_path="${download_dir}/${image_name}"
#if ! [ -f "$image_path" ]; then
#  curl -L -o "$download_dir" "$image_url"
#fi
#virsh vol-download --pool default --vol "$volume_name" --file "$image_path"
  end
end

DownloadAndImportBaseImage.run if __FILE__ == $0
