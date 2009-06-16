module Milton
  module Uploading
    module ClassMethods
      def self.extended(base)
        base.setup_callbacks
      end
      
      def setup_callbacks
        # Rails 2.1 fix for callbacks
        define_callbacks(:before_file_saved, :after_file_saved) if defined?(::ActiveSupport::Callbacks)
        after_save :save_uploaded_file
        after_file_saved :create_derivatives if @after_create_callbacks.delete(:create_derivatives)
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
      def self.included(base)
        # Rails 2.1 fix for callbacks
        base.define_callbacks *[:before_file_saved, :after_file_saved] if base.respond_to?(:define_callbacks)
      end
      
      # Set file=<uploaded file> on your model to handle an uploaded file.
      def file=(file)
        return nil if file.nil? || file.size == 0
        @upload           = Upload.new(file, self.class.milton_options)
        self.filename     = @upload.filename
        self.size         = @upload.size if respond_to?(:size=)
        self.content_type = Milton::File.mime_type?(@upload) if respond_to?(:content_type=)
      end
      
      protected
      
      def save_uploaded_file
        if @upload && !@upload.stored?
          callback :before_file_saved
          @attached_file = @upload.store(id)
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
      returning Storage::StoredFile.adapter(options[:storage]).create(filename, id, temp_path, options) do
        @stored = true
      end
    end

    protected
    
    def temp_path
      @tempfile.respond_to?(:path) ? @tempfile.path : @tempfile.to_s
    end
  end
end
