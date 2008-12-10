require File.dirname(__FILE__) + '/../../../../spec/spec_helper'

plugin_spec_dir = File.dirname(__FILE__)
ActiveRecord::Base.logger = Logger.new(plugin_spec_dir + "/debug.log")

load(File.dirname(__FILE__) + '/schema.rb')

Spec::Runner.configure do |config|
  config.fixture_path = File.join(File.dirname(__FILE__), 'fixtures/')
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
