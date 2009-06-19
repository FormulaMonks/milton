require 'milton/storage/stored_file'
require 'right_aws'
# these are required to generate HMAC:SHA1 signature for retrieving private
# files from S3
require 'base64'
require 'openssl'
require 'digest/sha1'

# TODO: Raise helpful errors on missing required options instead of letting
# right_aws fail cryptically

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
      
      # Copies this file to the given location on disk.
      # Note that this copies to a LOCAL location, not to another place on S3!
      def copy(destination)
        Milton.log "copying #{path} to #{destination}"

        s3   = RightAws::S3Interface.new(options[:storage_options][:access_key_id], options[:storage_options][:secret_access_key], :logger => Rails.logger)
        file = File.new(destination, 'wb')

        # stream the download as opposed to downloading the whole thing and reading
        # it all into memory at once since it might be gigantic...
        s3.get(options[:storage_options][:bucket], key) { |chunk| file.write(chunk) }
        file.close
      end

      def mime_type
        # TODO: implement
      end        

      # Generates a signed url to this resource on S3.
      # 
      # See doc for +signature+.
      def signed_url(expires_at=nil)
        "#{path}?AWSAccessKeyId=#{options[:storage_options][:access_key_id]}" +
        (expires_at ? "&Expires=#{expires_at.to_i}" : '') +
        "&Signature=#{signature(expires_at)}"
      end
      
      # Generates a signature for passing authorization for this file on to
      # another user without having to proxy the file.
      # 
      # See http://docs.amazonwebservices.com/AmazonS3/latest/index.html?RESTAuthentication.html
      # 
      # Optionally pass +expires_at+ to make the signature valid only until
      # given expiration date/time -- useful for temporary secure access to
      # files.
      def signature(expires_at=nil)
        CGI.escape(Base64.encode64(OpenSSL::HMAC.digest(
          OpenSSL::Digest::Digest.new('sha1'),
          options[:storage_options][:secret_access_key],
          "GET\n\n\n#{expires_at ? expires_at.to_i : ''}\n/#{options[:storage_options][:bucket]}/#{key}"
        )).chomp.gsub(/\n/, ''))
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
