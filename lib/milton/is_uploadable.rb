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
          
          options[:tempfile_path] ||= File.join(RAILS_ROOT, "tmp", "milton")
          
          self.milton_options.merge!(options)

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
          @upload           = UploadableFile.new(self, file)
          self.filename     = @upload.filename
          self.size         = @upload.size if respond_to?(:size=)
          self.content_type = @upload.content_type if respond_to?(:content_type=)
        end
        
        protected          
          def save_uploaded_file
            unless @upload.saved?
              callback :before_file_saved
              @upload.save
              callback :after_file_saved
            end
          end
      end
    end
    
    class UploadableFile < AttachableFile
      attr_reader :content_type, :filename, :size

      class << self
        def write_to_temp_file(data_or_path, options)
          FileUtils.mkdir_p(options[:tempfile_path]) unless File.exists?(options[:tempfile_path])
          
          tempfile = Tempfile.new("#{rand(Time.now.to_i)}", options[:tempfile_path])
          
          if data_or_path.is_a?(StringIO)
            tempfile.binmode
            tempfile.write data_or_path.read
            tempfile.close
          else
            tempfile.close
            FileUtils.cp((data_or_path.respond_to?(:path) ? data_or_path.path : data_or_path), tempfile.path)
          end
          
          tempfile
        end
      end

      def initialize(attachment, data_or_path)
        @has_been_saved = false
        @content_type   = data_or_path.content_type
        @filename       = AttachableFile.sanitize_filename(data_or_path.original_filename, attachment.class.milton_options) if respond_to?(:filename)
        @tempfile       = UploadableFile.write_to_temp_file(data_or_path, attachment.class.milton_options)
        @size           = File.size(self.temp_path)

        super attachment, filename
      end

      def saved?
        @has_been_saved
      end

      def save
        return true if self.saved?
        recreate_directory
        File.cp(temp_path, path)
        File.chmod(milton_options[:chmod], path)
        @has_been_saved = true
      end

      protected      
        def temp_path
          @tempfile.respond_to?(:path) ? @tempfile.path : @tempfile.to_s
        end
    end
  end
end