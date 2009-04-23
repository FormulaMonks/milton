require File.dirname(__FILE__) + '/../../../../test/test_helper'
raise "The tests require a Rails environment, try running them from within a Rails application." unless defined?(Rails)
raise "The tests require Contest or Shoulda gem loaded in your Rails environment" unless ActiveSupport::TestCase.respond_to?(:context)

require 'flexmock/test_unit'
require 'redgreen' rescue LoadError

$: << File.expand_path(File.dirname(__FILE__) + '/..')

load(File.dirname(__FILE__) + '/schema.rb')

def output_path
  File.join(File.dirname(__FILE__), 'output')
end

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures = false
  ActiveSupport::TestCase.fixture_path = File.join(File.dirname(__FILE__), 'fixtures/')
  
  # remove files created from previous test run, happens before instead of
  # after so you can view them after you run the tests
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
