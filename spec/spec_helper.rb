require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
require 'pathname'

plugin_spec_dir = File.dirname(__FILE__)
ActiveRecord::Base.logger = Logger.new(plugin_spec_dir + "/debug.log")

load(File.dirname(__FILE__) + '/schema.rb')

Spec::Runner.configure do |config|
  # have to set Test::Unit::TestCase.fixture_path until RSpec is fixed
  # (config.fixture_path seems to be ignored w/ Rails 2.2.2/Rspec 1.1.12)
  config.fixture_path = Test::Unit::TestCase.fixture_path = File.join(File.dirname(__FILE__), 'fixtures/')
  
  # remove files created from previous spec run, happens before instead of
  # after so you can view them after you run the specs
  FileUtils.rm_rf(File.join(File.dirname(__FILE__), 'output'))
end

def upload(file, type='image/jpg')
  fixture_file_upload file, type
end

class Attachment < ActiveRecord::Base
  is_uploadable :file_system_path => File.join(File.dirname(__FILE__), 'output')
end

class Image < ActiveRecord::Base
  is_image :file_system_path => File.join(File.dirname(__FILE__), 'output')
end
