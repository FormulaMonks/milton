require 'right_aws'

# this fakes S3 and makes it write to the file-system so we can check results
module RightAws
  raise "Must define S3_ROOT with fake S3 root before requiring s3_helper" unless defined?(S3_ROOT)
  
  class S3
    def buckets
      Dir.glob(S3_ROOT + '/*').collect do |bucket|
        Bucket.new(self, File.basename(bucket), Time.now, Owner.new(1, 'owner'))
      end
    end
    
    class Key
      def put(data=nil, perms=nil, headers={})
        Rails.logger.info "Putting to fake S3 store: #{filename}"
        FileUtils.mkdir_p(File.join(S3_ROOT, @bucket.name, File.dirname(@name)))
        FileUtils.cp(data.path, filename)
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
        File.join(S3_ROOT, @bucket.name, @name)
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
    def get(bucket, key, headers={}, &block)
      File.open(File.join(S3_ROOT, bucket, key), 'rb').each{ |io| block.call(io) }
    end

    def create_bucket(bucket, headers={})
      FileUtils.mkdir_p(File.join(S3_ROOT, bucket))
    end
  end
end
