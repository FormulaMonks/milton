require 'ftools'
require 'fileutils'

module Citrusbyte
  module Milton
    module Attachment
      def self.included(base)
        base.extend Citrusbyte::Milton::Attachment::AttachmentMethods
      end
      
      module AttachmentMethods
        def has_attachment_methods(options={})
          raise "Milton requires a filename column on #{table_name} table" unless column_names.include?("filename")
          
          # character used to seperate a filename from its derivative options, this
          # character will be stripped from all incoming filenames and replaced by
          # replacement
          options[:separator]        ||= '.'
          options[:replacement]      ||= '-'
          options[:file_system_path] ||= File.join(RAILS_ROOT, "public", table_name)
          options[:chmod]            ||= 0755
          
          AttachableFile.options = options
          
          validates_presence_of :filename
          
          before_destroy :destroy_attached_file
          
          extend  Citrusbyte::Milton::Attachment::ClassMethods
          include Citrusbyte::Milton::Attachment::InstanceMethods
        end
      end
      
      module ClassMethods
      end
      
      module InstanceMethods
        # Sets the filename to the given filename (sanitizes the given filename
        # as well)
        def filename=(name)
          write_attribute :filename, AttachableFile.sanitize_filename(name)
        end

        def path(options={})
          attached_file.path(options)
        end
                
        protected
          def attached_file
            @attached_file ||= AttachableFile.new(self, filename)
          end
          
          def destroy_attached_file
            attached_file.destroy
          end
      end
    end

    class AttachableFile
      class_inheritable_accessor :options

      class << self
        # Sanitizes the given filename, removes pathnames and the special chars
        # needed for options seperation for derivatives
        def sanitize_filename(filename)
          File.basename(filename, File.extname(filename)).gsub(/^.*(\\|\/)/, '').
            gsub(/[^\w]|#{Regexp.escape(options[:separator])}/, options[:replacement]).
            strip + File.extname(filename)
        end

        # Creates the given directory and sets it to the mode given in
        # attachment_options[:chmod]
        def recreate_directory(directory)
          FileUtils.mkdir_p(directory)
          File.chmod(options[:chmod], directory)
        end
      end
      
      def initialize(attachment, filename)
        @attachment = attachment
        @filename   = filename
      end

      # Returns the full path and filename to the file with the given options
      # If no options are given then returns the path and filename to the
      # original file
      def path(options={})
        options.empty? ? File.join(dirname, @filename) : DerivativeFile.new(@filename, options).path
      end
      
      # Returns the path to the file from the public root (assuming it's
      # stored somewhere under the public root)
      def public_path(options={})
        path(options).gsub(/.*public/, '')
      end
      
      def dirname
        File.join(root_path, partitioned_path)
      end
      
      # Returns true if the source file associated w/ the given model exists,
      # otherwise returns false
      def exists?
        File.exist?(path)
      end
      
      # Removes the file associated w/ this attachment from disk
      def destroy
        destroy_derivatives
        destroy_file
      end
      
      protected
        # Returns the file as a File object
        def file_reference
          @file_reference ||= File.new(path)
          @file_reference
        end
        
        # Gives the id partitioned portion of the path
        # FIXME: use padded 000/000/000 partitioning scheme
        def partitioned_path
          File.join((@attachment.id/2000000).floor.to_s, (@attachment.id%2000).to_s)
        end

        # The full path to the root of where files will be stored on disk
        def root_path
          self.class.options[:file_system_path]
        end

        # Recreates the directory this file will be stored in, as well as the
        # path for any derivatives of this file
        def recreate_directory
          self.class.recreate_directory(dirname) unless File.exists?(dirname)
        end
        
        # Derivatives of this Attachment ====================================
        
        # Returns an array of derivatives of this attachment
        def derivatives
          Dir.glob(Derivative.dirname_for(path)).collect do |filename|
            Derivative.from_filename(filename)
          end
        end
        
        # Recreates the directory this file will be stored in, as well as the
        # path for any derivatives of this file
        def recreate_derivative_directory
          dirname = Derivative.dirname_for(path)
          self.class.recreate_directory(dirname) unless File.exists?(dirname)
        end

        # Removes the derivatives folder for this file and all files within
        def destroy_derivatives
          FileUtils.rm_rf dirname if File.exists?(dirname)
        end
        
        # Removes the file from the filesystem
        def destroy_file
          FileUtils.rm path if File.exists?(path)
        end
    end
    
    class Derivative
      attr_reader :options
      
      class << self
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
          File.basename(filename, File.extname(filename)) + (append.blank? ? '' : "#{AttachableFile.options[:separator]}#{append}") + File.extname(filename)
        end
        
        def extract_options_from(filename)
          File.basename(filename, File.extname(filename))[(filename.rindex(AttachableFile.options[:separator]) + 1)..-1]
        end
        
        def from_filename(filename)
          Derivative.new(filename, options_from(extract_options_from(filename)))
        end
        
        # Gives the path to where derivatives of this file are stored.
        # Derivatives are any files which are based off of this file but are
        # not Attachments themselves (i.e. thumbnails, transcoded copies, 
        # etc...)
        def dirname_for(path)
          File.join(File.dirname(path), File.basename(path, File.extname(path)))
        end
      end
      
      def initialize(file, options)
        @file    = file
        @options = options
      end
      
      def filename
        self.class.filename_for(@file.path, options)
      end
      
      def path
        File.join(Derivative.dirname_for(@file.path), filename)
      end
      
      def exists?
        File.exists?(path)
      end
    end
  end
end
