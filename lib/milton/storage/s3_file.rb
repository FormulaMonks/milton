require File.join(File.dirname(__FILE__), 'stored_file')
require 'right_aws'

module Citrusbyte
  module Milton
    module Storage
      class S3File < StoredFile        
        def path
          # the URL to the file stored on S3
          File.join(dirname, filename)
        end

        def dirname
          id
        end

        def exists?
          bucket.key(path) ? true : false
        end
        
        def store(source)
          # send the given source file to the S3 bucket given in options and
          # write it to the given filename under dirname
          begin
            key = bucket.key(path)
            key.data = file
            key.put(nil, {'Content-type' => instance_read(:content_type)})
          rescue RightAws::AwsError => e
            raise
          end
        end
        
        def destroy
          # destroy the file
          begin
            if file = bucket.key(path)
              file.delete
            end
          rescue RightAws::AwsError
            # Ignore this.
          end
        end
        
        protected

        def s3
          @s3 ||= RightAws::S3.new(options[:access_key_id], options[:secret_access_key])
        end
        
        def bucket
          @bucket ||= s3.bucket(options[:bucket], true, 'public-read')
        end
      end
    end
  end
end
