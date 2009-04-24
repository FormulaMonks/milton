require File.dirname(__FILE__) + '/../../../../test/test_helper'
puts "\nWARNING: The tests require a Rails environment, try running them from within a Rails application.\n\n" unless defined?(Rails)
puts "\nWARNING: The tests require Contest or Shoulda gem loaded in your Rails environment\n\n" unless ActiveSupport::TestCase.respond_to?(:context)
unless %w( ActiveRecord::ConnectionAdapters::PostgreSQLAdapter ActiveRecord::ConnectionAdapters::MysqlAdapter ).include?(ActiveRecord::Base.connection.class.to_s)
  puts "\nWARNING: The tests will fail using any adapter other than PostgreSQL or MySQL because they depend on a proper transaction rollback that retains the current sequence, Milton itself will still work however.\n\n"
end

require 'flexmock/test_unit'
require 'redgreen' rescue LoadError

Rails.backtrace_cleaner.remove_silencers!
Rails.backtrace_cleaner.add_silencer do |line| 
  (%w( /opt /var lib/active_support lib/active_record vendor/gems vendor/rails )).any? { |dir| line.include?(dir) } 
end

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
  is_attachment :storage_options => { :root => output_path }
end

class Image < ActiveRecord::Base
  is_attachment :storage_options => { :root => output_path }, :processors => { :thumbnail => { :postprocessing => true } }
end
