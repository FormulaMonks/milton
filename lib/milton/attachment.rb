require 'ftools'
require 'fileutils'
require 'milton/derivatives/derivative'

module Milton
  module Attachment
    # Call is_attachment with your options in order to add attachment
    # functionality to your ActiveRecord model.
    # 
    # TODO: list options
    def is_attachment(options={})
      # Check to see that it hasn't already been extended so that subclasses
      # can redefine is_attachment from their superclasses and overwrite 
      # options w/o losing the superclass options.
      unless respond_to?(:has_attachment_methods)
        extend Milton::Attachment::AttachmentMethods
        class_inheritable_accessor :milton_options
      end
      has_attachment_methods(options)
    end
    
    module AttachmentMethods        
      def require_column(column, message)
        begin
          raise message unless column_names.include?(column)
        rescue ActiveRecord::StatementInvalid => i
          # table doesn't exist yet, i.e. hasn't been migrated in...
        end
      end
      
      def has_attachment_methods(options={})
        require_column 'filename', "Milton requires a filename column on #{class_name} table"
        
        # It's possible that this is being included from a class and a sub
        # class of that class, in which case we need to merge the existing
        # options up.
        self.milton_options ||= {}
        milton_options.merge!(options)
        
        # Character used to seperate a filename from its derivative options, this
        # character will be stripped from all incoming filenames and replaced by
        # replacement
        milton_options[:separator]        ||= '.'
        milton_options[:replacement]      ||= '-'          
        milton_options[:tempfile_path]    ||= File.join(Rails.root, "tmp", "milton")
        milton_options[:storage]          ||= :disk
        milton_options[:storage_options]  ||= {}
        milton_options[:processors]       ||= {}
        milton_options[:uploading]        ||= true
        
        # Set to true to allow on-demand processing of derivatives. This can
        # be rediculously slow because it requires that the existance of the
        # derivative is checked each time it's requested -- throw in S3 and
        # that becomes a huge lag. Reccommended only for prototyping.
        milton_options[:postproccess]     ||= false
        
        # TODO: Write about recipes
        #   * They're refered to by name in #path
        #   * They're an order of derivations to make against this attachment
        #   * They run in the order defined
        #   * They are created and run when the AR model is created
        #   * They're necessary when +:postprocessing+ is turned off
        milton_options[:recipes]          ||= {}
        milton_options[:recipes].each do |name, steps|
          steps = [steps] unless steps.is_a?(Array)
          steps.each do |step|
            step.each { |processor, options| Milton.try_require "milton/derivatives/#{processor}", "No '#{processor}' processor found for Milton" }
          end
        end

        # TODO: Write about storage options
        #   * Late binding (so right_aws is only req'd if you use S3)
        Milton.try_require "milton/storage/#{milton_options[:storage]}_file", "No '#{milton_options[:storage]}' storage found for Milton"

        # TODO: initialize these options in DiskFile
        if milton_options[:storage] == :disk
          # root of where the underlying files are stored (or will be stored)
          # on the file system
          milton_options[:storage_options][:root]  ||= File.join(Rails.root, "public", table_name)
          milton_options[:storage_options][:root]    = File.expand_path(milton_options[:storage_options][:root])
          # mode to set on stored files and created directories
          milton_options[:storage_options][:chmod] ||= 0755
        end
                  
        validates_presence_of :filename
        
        after_destroy :destroy_attached_file
        after_create :create_derivatives

        include Milton::Attachment::InstanceMethods
        
        if milton_options[:uploading]
          require 'milton/uploading'
          extend  Milton::Uploading::ClassMethods
          include Milton::Uploading::InstanceMethods
        end
      end        
    end
    
    # These get mixed in to your model when you use Milton
    module InstanceMethods
      # Sets the filename to the given filename (sanitizes the given filename
      # as well)
      #
      # TODO: change the filename on the underlying file system on save so as
      # not to orphan the file
      def filename=(name)
        write_attribute :filename, Storage::StoredFile.sanitize_filename(name, self.class.milton_options)
      end

      # Returns the content_type of this attachment, tries to determine it if
      # hasn't been determined yet or is not saved to the database
      def content_type
        return self[:content_type] unless self[:content_type].blank?
        self.content_type = attached_file.mime_type
      end
      
      # Sets the content type to the given type
      def content_type=(type)
        write_attribute :content_type, type.to_s.strip
      end

      # Simple helper, same as path except returns the directory from
      # .../public/ on, i.e. for showing images in your views.
      #
      #   @asset.path        => /var/www/site/public/assets/000/000/001/313/milton.jpg
      #   @asset.public_path => /assets/000/000/001/313/milton.jpg
      #
      # Can send a different base path than public if you want to give the
      # path from that base on, useful if you change your root path to
      # somewhere else.
      def public_path(options={}, base='public')
        path(options).gsub(/.*?\/#{base}/, '')
      end
      
      # The path to the file.
      def path(options=nil)
        return attached_file.path if options.nil?
        process(options).path
      end
      
      protected
      
      # Meant to be used as an after_create filter -- loops over all the
      # recipes and processes them to create the derivatives.
      def create_derivatives
        milton_options[:recipes].each{ |name, recipe| process(name, true) } if milton_options[:recipes].any?
      end
      
      # Process the given options to produce a final derivative. +options+
      # takes a Hash of options to process or the name of a pre-defined
      # recipe which will be looked up and processed.
      # 
      # Pass +force = true+ to force processing regardless of if 
      # +:postprocessing+ is turned on or not.
      # 
      # Returns the final Derivative of all processors in the recipe.
      def process(options, force=false)
        options = milton_options[:recipes][options] unless options.is_a?(Hash)
        options = [options] unless options.is_a?(Array)
        
        source = attached_file
        options.each do |recipe|
          recipe.each do |processor, opts|
            source = Derivative.factory(processor, source, opts, self.class.milton_options).process_if(process? || force).file
          end
        end
        source
      end
      
      # Returns true if derivaties of the attachment should be processed,
      # returns false if no processing should be done when a derivative is
      # requested.
      # 
      # No processing also means the derivative won't be checked for
      # existance (since that can be slow) so w/o postprocessing things will
      # be much faster but #path will happily return the paths to Derivatives
      # which don't exist.
      # 
      # It is highly recommended that you turn +:postprocessing+ off for
      # anything but prototyping, and instead use recipes and refer to them
      # via #path. +:postprocessing+ relies on checking for existance which
      # will kill any real application.
      def process?
        self.class.milton_options[:postprocessing]
      end
      
      # A reference to the attached file, this is probably what you want to
      # overwrite to introduce a new behavior
      #
      # i.e. 
      #   have attached_file return a ResizeableFile, or a TranscodableFile
      def attached_file
        @attached_file ||= Storage::StoredFile.adapter(self.class.milton_options[:storage]).new(filename, id, self.class.milton_options)
      end
      
      # Clean the file from the filesystem
      def destroy_attached_file
        attached_file.destroy
      end
    end
  end
end
