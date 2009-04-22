require File.join(File.dirname(__FILE__), 'stored_file')
require 'right_aws'

module Citrusbyte
  module Milton
    module Storage
      class S3File < StoredFile
        def path
          "http://#{bucket}.s3.amazonaws.com/#{key}"
        end
        
        def dirname
          id
        end

        def exists?
          bucket.key(key).exists?
        end
        
        def store(source)
          Milton.log "storing #{source} to #{path}"
          bucket.put(key, File.open(source), {}, 'public-read')
        end
        
        def destroy
          Milton.log "destroying #{path}"
          bucket.key(key).try(:delete)
        end
        
        protected

        def key
          "#{dirname}/#{filename}"
        end

        def s3
          @s3 ||= RightAws::S3.new(
            options[:storage_options][:access_key_id], 
            options[:storage_options][:secret_access_key], 
            { :protocol => 'http', :port => 80, :logger => Rails.logger }
          )
        end
        
        def bucket
          @bucket ||= s3.bucket(options[:storage_options][:bucket], true, 'public-read')
        end
      end
    end
  end
end
