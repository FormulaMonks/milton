require 'ftools'
require 'fileutils'
require File.join(File.dirname(__FILE__), 'derivatives', 'derivative')
require File.join(File.dirname(__FILE__), 'storage', 'disk_file')
require File.join(File.dirname(__FILE__), 'storage', 's3_file')

module Citrusbyte
  module Milton
    module Attachment      
      def self.included(base)
        base.class_inheritable_accessor :milton_options
        base.milton_options = {}
        base.extend Citrusbyte::Milton::Attachment::AttachmentMethods
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

          # Character used to seperate a filename from its derivative options, this
          # character will be stripped from all incoming filenames and replaced by
          # replacement
          options[:separator]        ||= '.'
          options[:replacement]      ||= '-'
          # Set to true to allow on-demand processing of derivatives. This can
          # be rediculously slow because it requires that the existance of the
          # derivative is checked each time it's requested -- throw in S3 and
          # that becomes a huge lag. Reccommended only for prototyping.
          options[:postproccess]     ||= false
          options[:tempfile_path]    ||= File.join(Rails.root, "tmp", "milton")
          options[:storage]          ||= :disk
          options[:storage_options]  ||= {}

          if options[:storage] == :disk
            # root of where the underlying files are stored (or will be stored)
            # on the file system
            options[:storage_options][:root]  ||= File.join(Rails.root, "public", table_name)
            # mode to set on stored files and created directories
            options[:storage_options][:chmod] ||= 0755
          end
                              
          self.milton_options.merge!(options)
          
          validates_presence_of :filename
          
          before_destroy :destroy_attached_file
          
          include Citrusbyte::Milton::Attachment::InstanceMethods
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
          write_attribute :filename, Storage::StoredFile.sanitize_filename(name, self.milton_options)
        end

        # Returns the content_type of this attachment, tries to determine it if
        # hasn't been determined yet or is not saved to the database
        def content_type
          return self[:content_type] unless self[:content_type].blank?
          self.content_type = file_reference.mime_type? if file_reference.respond_to?(:mime_type?)
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
        
        # The path to the file, takes an optional hash of options which can be
        # used to determine a particular derivative of the file desired
        def path(options={})
          options.empty? ? attached_file.path : Derivative.new(attached_file, options).path
        end
        
        protected
        
        # Returns true if derivaties of the attachment should be processed,
        # returns false if no processing should be done when a derivative is
        # requested.
        def process?
          self.class.milton_options[:postprocessing]
        end
        
        # Anything that needs to create derivatives on creation should override
        # this
        def create_derivatives;end;
        
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
end
