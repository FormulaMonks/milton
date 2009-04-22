require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
require 'pathname'

plugin_spec_dir = File.dirname(__FILE__)

load(File.dirname(__FILE__) + '/schema.rb')

def output_path
  File.join(File.dirname(__FILE__), 'output')
end

Spec::Runner.configure do |config|
  # have to set Test::Unit::TestCase.fixture_path until RSpec is fixed
  # (config.fixture_path seems to be ignored w/ Rails 2.2.2/Rspec 1.1.12)
  config.fixture_path = ActiveSupport::TestCase.fixture_path = File.join(File.dirname(__FILE__), 'fixtures/')
  
  # remove files created from previous spec run, happens before instead of
  # after so you can view them after you run the specs
  FileUtils.rm_rf(output_path)
end

def upload(file, type='image/jpg')
  ActionController::TestUploadedFile.new(ActionController::TestCase.fixture_path + file, type)
end

class Attachment < ActiveRecord::Base
  is_uploadable :storage_options => { :root => output_path }
end

class Image < ActiveRecord::Base
  is_image :storage_options => { :root => output_path }
end
