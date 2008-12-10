require 'milton/attachment'
require 'milton/is_image'
require 'milton/is_resizeable'
require 'milton/is_uploadable'

module Citrusbyte
  module Milton
    def self.included(base)
      base.extend Citrusbyte::Milton::BaseMethods
      base.extend Citrusbyte::Milton::ClassMethods
      base.extend Citrusbyte::Milton::IsUploadable::IsMethods
      base.extend Citrusbyte::Milton::IsResizeable::IsMethods
      base.extend Citrusbyte::Milton::IsImage::IsMethods
    end
    
    module BaseMethods
      protected
        def ensure_attachment_methods(options={})
          options[:file_system_path] ||= File.join(RAILS_ROOT, "public", table_name)
          options[:file_system_path] = options[:file_system_path][1..-1] if options[:file_system_path].first == '/'
          
          unless included_modules.include?(Citrusbyte::Milton::Attachment)
            include Citrusbyte::Milton::Attachment
            has_attachment_methods(:file_system_path => options[:file_system_path])
          end
        end
    end
    
    module ClassMethods
      def random_string(length)
         Digest::SHA1.hexdigest((1..6).collect { (i = rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join).slice(1..length)
      end
    end
  end
end