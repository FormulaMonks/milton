require File.join(File.dirname(__FILE__), 'derivatives', 'thumbnail')

module Citrusbyte
  module Milton    
    module IsResizeable
      def self.included(base)
        base.extend IsMethods
      end

      module IsMethods
        def is_resizeable(options={})
          ensure_attachment_methods options
                    
          self.milton_options.deep_merge!(options)

          include Citrusbyte::Milton::IsResizeable::InstanceMethods
        end
      end

      module InstanceMethods                
        def path(options={})
          options.empty? ? attached_file.path : Thumbnail.new(attached_file, options).path
        end
      end        
    end
  end
end
