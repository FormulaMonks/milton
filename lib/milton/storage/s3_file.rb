require 'milton/storage/stored_file'
require 'right_aws'

# TODO: Raise helpful errors on missing required options instead of letting
# right_aws fail cryptically

module Citrusbyte
  module Milton
    module Storage
      class S3File < StoredFile
        def path
          "http://#{options[:storage_options][:bucket]}.s3.amazonaws.com/#{key}"
        end
        
        def dirname
          id
        end

        def exists?
          bucket.key(key).exists?
        end
        
        def store(source)
          Milton.log "storing #{source} to #{path} (#{options[:storage_options][:permissions]})"
          bucket.put(key, File.open(source), {}, options[:storage_options][:permissions])
        end
        
        def destroy
          Milton.log "destroying #{path}"
          bucket.key(key).try(:delete)
        end
        
        def mime_type
          # TODO: implement
        end
        
        protected

        def key
          "#{dirname}/#{filename}"
        end

        def s3
          @s3 ||= RightAws::S3.new(
            options[:storage_options][:access_key_id], 
            options[:storage_options][:secret_access_key], 
            { :protocol => http? ? 'http' : 'https', :port => http? ? 80 : 443, :logger => Rails.logger }
          )
        end
        
        def http?
          options[:storage_options].has_key?(:protocol) && options[:storage_options][:protocol] == 'http'
        end
        
        def bucket
          @bucket ||= s3.bucket(options[:storage_options][:bucket], true, options[:storage_options][:permissions])
        end
      end
    end
  end
end
