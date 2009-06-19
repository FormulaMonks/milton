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

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures = false
  ActiveSupport::TestCase.fixture_path = File.join(File.dirname(__FILE__), 'fixtures/')

  @@output_path = File.expand_path(File.join(File.dirname(__FILE__), 'output'))
  cattr_reader :output_path
  def output_path;ActiveSupport::TestCase.output_path;end;
  
  # remove files created from previous test run, happens before instead of
  # after so you can view them after you run the tests
  FileUtils.rm_rf(output_path)
  
  def upload(file, type='image/jpg')
    ActionController::TestUploadedFile.new(fixture_file(file), type)
  end
  
  def fixture_file(file)
    ActionController::TestCase.fixture_path + file
  end
end

module ActiveSupport::Testing::Declarative
  def pending_test(name, &block)
    test(name) do
      puts "\nPENDING: #{name} (in #{eval('"#{__FILE__}:#{__LINE__}"', block.binding)})"
    end
  end
end

class Attachment < ActiveRecord::Base
  is_attachment :storage_options => { :root => ActiveSupport::TestCase.output_path }
end

class Image < ActiveRecord::Base
  is_attachment :storage_options => { :root => ActiveSupport::TestCase.output_path }
end

class Net::HTTP
  def connect
    raise "Trying to hit the interwebz!!!"
  end
end

S3_ROOT = File.join(ActiveSupport::TestCase.output_path, 's3') 
require File.join(File.dirname(__FILE__), 's3_helper')

class S3File
  class << self
    def path(url)
      url.scan /http:\/\/(.*)\.s3.amazonaws.com\/(.*)\/(.*)/
      File.join(S3_ROOT, $1, $2, $3)
    end
    
    def exists?(url)
      File.exist?(path(url))
    end
  end
end
