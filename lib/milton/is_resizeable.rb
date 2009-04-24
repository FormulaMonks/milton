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

          self.milton_options.merge!(options)
          self.milton_options[:resizeable]         ||= {}
          self.milton_options[:resizeable][:sizes] ||= {}

          after_create :create_derivatives

          include Citrusbyte::Milton::IsResizeable::InstanceMethods
        end
      end

      module InstanceMethods
        def path(options={})
          return super() if options.empty?
          Thumbnail.new(attached_file, options, self.class.milton_options).process_if(process?).path
        end
        
        protected
        
        def create_derivatives
          self.class.milton_options[:resizeable][:sizes].each do |name, options|
            Thumbnail.process(attached_file, options.merge(:name => name), self.class.milton_options)
          end
        end
      end        
    end
  end
end
