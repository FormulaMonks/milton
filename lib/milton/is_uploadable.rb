module Citrusbyte
  module Milton
    module IsUploadable
      def self.included(base)
        base.extend IsMethods
      end

      module IsMethods
        @@tempfile_path = File.join(RAILS_ROOT, "tmp", "milton")
        mattr_reader :tempfile_path

        def is_uploadable(options = {})
          raise "Milton's is_uploadable requires a filename column on #{class_name} table" unless column_names.include?("filename")

          options[:min_size]     ||= 1
          options[:max_size]     ||= 4.megabytes
          options[:size]         ||= (options[:min_size]..options[:max_size])
          options[:partitioning] ||= true

          ensure_attachment_methods options

          class_inheritable_accessor :uploadable_options
          self.uploadable_options = options

          after_save :save_uploaded_file

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
          @uploaded_file    = UploadedFile.new(file, self.class.tempfile_path)
          self.content_type = @uploaded_file.content_type
          self.filename     = @uploaded_file.filename
          self.size         = @uploaded_file.size if respond_to?(:size=)
        end
        
        protected          
          def save_uploaded_file
            unless @uploaded_file.saved?
              callback :before_file_saved
              @uploaded_file.save(full_filename, self.attachment_options[:chmod])
              callback :after_file_saved
              self.path = partitioned_path
              save
            end
          end
      end
      
      class UploadedFile
        attr_reader :content_type, :filename, :size
        
        def initialize(data_or_path, tempfile_path)
          @has_been_saved = false
          @content_type   = data_or_path.content_type
          @filename       = data_or_path.original_filename if respond_to?(:filename)
          
          FileUtils.mkdir_p(tempfile_path) unless File.exists?(tempfile_path)
          
          @file = Tempfile.new("#{rand(Time.now.to_i)}#{filename || 'file'}", tempfile_path) do |tmp|
            if data_or_path.is_a?(StringIO)
              tmp.binmode
              tmp.write data
              tmp.close
            else
              tmp.close
              FileUtils.cp file, tmp.path
            end
          end
          
          @size = File.size(self.path)
        end
        
        def saved?
          @has_been_saved
        end
        
        def save(filename, chmod)
          return true if self.saved?
          File.cp(self.path, filename)
          File.chmod(chmod, filename)
          @has_been_saved = true
        end
  
        protected
          def path
            @file.respond_to?(:path) ? @file.path : @file.to_s
          end
      end
    end
  end
end