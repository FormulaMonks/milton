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
    ActionController::TestUploadedFile.new(ActionController::TestCase.fixture_path + file, type)
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
  is_attachment :storage_options => { :root => ActiveSupport::TestCase.output_path }, :processors => { :thumbnail => { :postprocessing => true } }
end

require 'right_aws'

# this fakes S3 and makes it write to the file-system so we can check results
module RightAws
  ROOT = File.join(ActiveSupport::TestCase.output_path, 's3') unless defined?(ROOT)
  
  class S3
    def buckets
      Dir.glob(ROOT + '/*').collect do |bucket|
        Bucket.new(self, File.basename(bucket), Time.now, Owner.new(1, 'owner'))
      end
    end
    
    class Key
      def put(data=nil, perms=nil, headers={})
        Rails.logger.info "Putting to fake S3 store: #{filename}"
        FileUtils.mkdir_p(File.join(ROOT, @bucket.name, File.dirname(@name)))
        File.open(filename, "w") { |f| f.write(data) }
      end
      
      def delete
        Rails.logger.info "Deleting from fake S3 store: #{filename}"        
        FileUtils.rm(filename)
      end
      
      def exists?
        File.exists?(filename)
      end
      
      private
      
      def filename
        File.join(File.join(ROOT, @bucket.name), @name)
      end
    end
    
    class Bucket
      def key(key_name, head=false)
        Key.new(self, key_name, nil, {}, {}, Time.now, Time.now.to_s, 100, '', Owner.new(1, 'owner'))
      end
    end
    
    class Grantee
      def apply
        true
      end
    end
  end

  class S3Interface < RightAwsBase
    def create_bucket(bucket, headers={})
      FileUtils.mkdir_p(File.join(ROOT, bucket))
    end
  end
end

class S3File
  class << self
    def path(url)
      url.scan /http:\/\/(.*)\.s3.amazonaws.com\/(.*)\/(.*)/
      File.join(RightAws::ROOT, $1, $2, $3)
    end
    
    def exists?(url)
      File.exist?(path(url))
    end
  end
end

class Net::HTTP
  def connect
    raise "Trying to hit the interwebz!!!"
  end
end
