require 'milton/attachment'
require 'milton/is_image'
require 'milton/is_resizeable'
require 'milton/is_uploadable'

module Citrusbyte
  module Milton
    # Raised when a file which was expected to exist appears not to exist
    class MissingFileError < StandardError;end;

    # Some definitions for file semantics used throughout Milton, understanding
    # this will make understanding the code a bit easier and avoid ambiguity:
    #
    # path:
    #   the full path to a file or directory in the filesystem
    #     /var/log/apache2 or /var/log/apache2/access.log
    #   can also be defined as:
    #     path == dirname + filename
    #     path == dirname + basename + extension
    #
    # dirname:
    #   the directory portion of the path to a file or directory, all the chars
    #   up to the final /
    #     /var/log/apache2            => /var/log
    #     /var/log/apache2/           => /var/log/apache2
    #     /var/log/apache2/access.log => /var/log/apache2
    #
    # basename:
    #   the portion of a filename *with no extension* (ruby's "basename" may or
    #   may not have an extension), all the chars after the last / and before
    #   the last .
    #     /var/log/apache2                 => apache2
    #     /var/log/apache2/                => nil
    #     /var/log/apache2/access.log      => access
    #     /var/log/apache2/access.2008.log => access.2008
    #
    # extension:
    #   the extension portion of a filename w/ no preceding ., all the chars
    #   after the final .
    #     /var/log/apache2                 => nil
    #     /var/log/apache2/                => nil
    #     /var/log/apache2/access.log      => log
    #     /var/log/apache2/access.2008.log => log
    # 
    # filename:
    #   the filename portion of a path w/ extension, all the chars after the
    #   final /
    #     /var/log/apache2                 => apache2
    #     /var/log/apache2/                => nil
    #     /var/log/apache2/access.log      => access.log
    #     /var/log/apache2/access.2008.log => access.2008.log
    #   can also be defined as:
    #     filename == basename + (extension ? '.' + extension : '')
    #
    
    def self.included(base)
      base.extend Citrusbyte::Milton::BaseMethods
      base.extend Citrusbyte::Milton::IsUploadable::IsMethods
      base.extend Citrusbyte::Milton::IsResizeable::IsMethods
      base.extend Citrusbyte::Milton::IsImage::IsMethods
    end
    
    module BaseMethods
      protected
        # The attachment methods give the core of Milton's file-handling, so
        # various extensions can use this when they're included to make sure
        # that the core attachment methods are available
        def ensure_attachment_methods(options={})
          unless included_modules.include?(Citrusbyte::Milton::Attachment)
            include Citrusbyte::Milton::Attachment
            has_attachment_methods(options)
          end
        end
    end
  end
end

ActiveRecord::Base.send(:include, Citrusbyte::Milton)