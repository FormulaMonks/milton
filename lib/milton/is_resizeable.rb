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

          options[:resizeable] ||= {}
          options[:resizeable][:sizes] ||= {}
          self.milton_options.deep_merge!(options)

          after_create :create_derivatives

          include Citrusbyte::Milton::IsResizeable::InstanceMethods
        end
      end

      module InstanceMethods
        def path(options={})
          options.empty? ? attached_file.path : Thumbnail.new(attached_file, options, self.class.milton_options.merge(:process => process?)).path
        end
        
        protected
        
        def create_derivatives
          thumbnails = self.class.milton_options[:resizeable][:sizes].each do |name, options|
            Thumbnail.new(attached_file, options.merge(:name => name), self.class.milton_options.merge(:process => true)).path
          end
        end
      end        
    end
  end
end
