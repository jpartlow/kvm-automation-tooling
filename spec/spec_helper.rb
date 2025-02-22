# frozen_string_literal: true

require 'rspec-puppet'

fixture_path = File.expand_path(File.join(__dir__, 'fixtures'))

RSpec.configure do |c|
  # Include the Bolt .modules directory as part of the modulepath for dependencies.
  c.module_path     = [File.join(fixture_path, 'modules'), File.join(__dir__, '..', '.modules')].join(':')
  c.manifest        = File.join(fixture_path, 'manifests', 'site.pp')
  c.environmentpath = File.join(Dir.pwd, 'spec')
end
