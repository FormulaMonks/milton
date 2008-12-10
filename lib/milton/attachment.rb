require 'ftools'
require 'fileutils'

module Citrusbyte
  module Milton
    module Attachment
      # character used to seperate a filename from its derivative options, this
      # character will be stripped from all incoming filenames and replaced by
      # REPLACEMENT
      SEPARATOR   = '.'
      REPLACEMENT = '-'
      
      def self.included(base)
        base.extend Citrusbyte::Milton::Attachment::AttachmentMethods
      end
      
      module AttachmentMethods
        def has_attachment_methods(options={})
          raise "Milton requires filename and path columns on #{table_name} table" unless column_names.include?("filename") && column_names.include?("path")
          
          options[:file_system_path] ||= File.join(RAILS_ROOT, "public", table_name)
          options[:file_system_path] = options[:file_system_path][1..-1] if options[:file_system_path].first == '/'
          options[:chmod] ||= 0755
          
          class_inheritable_accessor :attachment_options
          self.attachment_options = options
          
          validates_presence_of :filename
          
          after_save :recreate_directories
          before_destroy :destroy_derivatives
          
          extend  Citrusbyte::Milton::Attachment::ClassMethods
          include Citrusbyte::Milton::Attachment::InstanceMethods
        end
      end
      
      module ClassMethods
        # Given a string of attachment options, splits them out into a hash,
        # useful for things that take options on the query string or from
        # filenames
        def options_from(string)
          Hash[*(string.split('_').collect { |option| 
            key, value = option.split('=')
            [ key.to_sym, value ]
          }).flatten]
        end

        # Merges the given options to build a derviative filename and returns
        # the resulting filename.
        def filename_for(filename, options={})
          append = options.collect{ |k, v| "#{k}=#{v}" }.sort.join('_')
          File.basename(filename, File.extname(filename)) + (append.blank? ? '' : "#{SEPARATOR}#{append}") + File.extname(filename)
        end
        
        # Sanitizes the given filename, removes pathnames and the special chars
        # needed for options seperation for derivatives
        def sanitize_filename(filename)
          File.basename(filename, File.extname(filename)).gsub(/^.*(\\|\/)/, '').gsub(/[^\w]|#{Regexp.escape(SEPARATOR)}/, REPLACEMENT).strip + File.extname(filename)
        end

        # Creates the given directory and sets it to the mode given in
        # attachment_options[:chmod]
        def recreate_directory(directory)
          FileUtils.mkdir_p(directory)
          File.chmod(attachment_options[:chmod], directory)
        end
      end
      
      module InstanceMethods
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

        # Sets the filename to the given filename (sanitizes the given filename
        # as well)
        def filename=(name)
          write_attribute :filename, self.class.sanitize_filename(name)
        end

        # Instance wrapper for filename_for that uses this attachment's 
        # filename
        def filename_for(options={})
          self.class.filename_for(filename, options)
        end
        
        # Returns the full path and filename to the file with the given options
        # If no options are given then returns the path and filename to the
        # original file
        def full_filename(options={})
          return File.join(base_storage_path, partitioned_path, filename_for(options)) if options.empty?
          File.join(derivative_path, filename_for(options))
        end
        
        # Returns the path to the file from the public root (assuming it's
        # stored somewhere under the public root)
        def public_filename(options={})
          full_filename(options).gsub(/.*public/, '')
        end
        
        protected
          # Returns the file as a File object
          def file_reference
            @file_reference ||= File.new(full_filename)
            @file_reference
          end
                  
          # Returns true if the source file associated w/ the given model exists,
          # otherwise returns false
          def exists?
            File.exist?(full_filename)
          end

          # Gives the path to where derivatives of this file are stored.
          # Derivatives are any files which are based off of this file but are
          # not Attachments themselves (i.e. thumbnails, transcoded copies, 
          # etc...)
          def derivative_path
            filename = full_filename
            File.join(File.dirname(filename), File.basename(filename, File.extname(filename)))
          end
          
          # Returns the filename to a derivative w/ the given options (whether
          # it exists or not)
          def derivative_filename(options={})
            File.join(derivative_path, filename_for(options))
          end

          # Returns an array of derivatives of this image
          def derivatives
            Dir.glob(derivative_path)
          end

          def extract_attributes
            beginning_of_attributes = filename.rindex(SEPARATOR) + 1
            options = File.basename(filename, File.extname(filename))[beginning_of_attributes..-1]
          end

          # Gives the id partitioned portion of the path
          def partitioned_path
            File.join((id/2000000).floor.to_s, (id%2000).to_s)
          end

          # The full path to the root of where files will be stored on disk
          def base_storage_path
            self.attachment_options[:file_system_path]
          end

          # def base_path
          #   @base_path ||= File.join(RAILS_ROOT, "public")
          # end
          
          # Recreates the directory this file will be stored in, as well as the
          # path for any derivatives of this file
          def recreate_directories
            [ File.dirname(full_filename), derivative_path ].each do |dirname|
              self.class.recreate_directory(dirname) unless File.exists?(dirname)
            end
          end
                    
          # Removes the file associated w/ this attachment from disk
          def destroy_file
            FileUtils.rm full_filename if File.exists?(full_filename)
          end
          
          # Removes the derivatives folder for this file and all files within
          def destroy_derivatives
            FileUtils.rm_rf derivative_path if File.exists?(derivative_path)
          end
      end
    end
  end
end
