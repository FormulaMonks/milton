module Citrusbyte
  module Milton
    module IsUploadable
      def self.included(base)
        base.extend IsMethods
      end

      module IsMethods
        def is_uploadable(options = {})
          # TODO: implement size validations
          # options[:min_size]      ||= 1
          # options[:max_size]      ||= 4.megabytes
          # options[:size]          ||= (options[:min_size]..options[:max_size])
          
          ensure_attachment_methods options
          
          self.milton_options.deep_merge!(options)

          after_create :save_uploaded_file

          extend  Citrusbyte::Milton::IsUploadable::ClassMethods
          include Citrusbyte::Milton::IsUploadable::InstanceMethods
        end
      end

      module ClassMethods
        def self.extended(base)
          # Rails 2.1 fix for callbacks
          if defined?(::ActiveSupport::Callbacks)
            base.define_callbacks :before_file_saved, :after_file_saved
          end
        end
      
        unless defined?(::ActiveSupport::Callbacks)
          def before_file_saved(&block) 
            write_inheritable_array(:before_file_saved, [block])
          end
        
          def after_file_saved(&block)
            write_inheritable_array(:after_file_saved, [block])
          end
        end
      end
    
      module InstanceMethods 
        FILENAME_REGEX = /^[^\/\\]+$/
        
        def self.included(base)
          # Nasty rails 2.1 fix for callbacks
          base.define_callbacks *[:before_file_saved, :after_file_saved] if base.respond_to?(:define_callbacks)
        end
        
        def file=(file)
          return nil if file.nil? || file.size == 0
          @upload           = Upload.new(file, self.class.milton_options)
          self.filename     = @upload.filename
          self.size         = @upload.size if respond_to?(:size=)
          self.content_type = @upload.content_type if respond_to?(:content_type=)
        end
        
        protected
        
        def save_uploaded_file
          unless @upload.stored?
            callback :before_file_saved
            @upload.store(id)
            callback :after_file_saved
          end
        end
      end
    end
    
    class Upload
      attr_reader :content_type, :filename, :size, :options
      
      def initialize(data_or_path, options)
        @stored       = false
        @tempfile     = Milton::Tempfile.create(data_or_path, options[:tempfile_path])
        @content_type = data_or_path.content_type
        @filename     = Storage::StoredFile.sanitize_filename(data_or_path.original_filename, options) if respond_to?(:filename)
        @size         = File.size(self.temp_path)
        @options      = options
      end

      def stored?
        @stored
      end

      def store(id)
        return true if stored?
        Storage::StoredFile.adapter(options[:storage]).create(filename, temp_path, options.merge(:id => id))
        @stored = true
      end

      protected
      
      def temp_path
        @tempfile.respond_to?(:path) ? @tempfile.path : @tempfile.to_s
      end
    end
  end
end