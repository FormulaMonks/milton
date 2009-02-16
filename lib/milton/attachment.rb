require 'ftools'
require 'fileutils'

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
          
          # character used to seperate a filename from its derivative options, this
          # character will be stripped from all incoming filenames and replaced by
          # replacement
          options[:separator]        ||= '.'
          options[:replacement]      ||= '-'
          
          # root of where the underlying files are stored (or will be stored)
          # on the file system
          options[:file_system_path] ||= File.join(RAILS_ROOT, "public", table_name)
          
          # mode to set on stored files and created directories
          options[:chmod]            ||= 0755
          
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
          write_attribute :filename, AttachableFile.sanitize_filename(name, self.milton_options)
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
          attached_file.path(options)
        end
                
        protected
          # A reference to the attached file, this is probably what you want to
          # overwrite to introduce a new behavior
          #
          # i.e. 
          #   have attached_file return a ResizeableFile, or a TranscodableFile
          def attached_file
            @attached_file ||= AttachableFile.new(self, filename)
          end
          
          # Clean the file from the filesystem
          def destroy_attached_file
            attached_file.destroy
          end
      end
    end

    # AttachableFile is what Milton uses to interface between your model and
    # the underlying file. Rather than just pushing a whole bunch of methods
    # into your model, you get a reference to an AttachableFile (or something
    # that extends AttachableFile).
    class AttachableFile
      class << self
      # Sanitizes the given filename, removes pathnames and the special chars
      # needed for options seperation for derivatives
      def sanitize_filename(filename, options)
        File.basename(filename, File.extname(filename)).gsub(/^.*(\\|\/)/, '').
          gsub(/[^\w]|#{Regexp.escape(options[:separator])}/, options[:replacement]).
          strip + File.extname(filename)
      end

      # Creates the given directory and sets it to the mode given in
      # options[:chmod]
      def recreate_directory(directory, options)
        return true if File.exists?(directory)
        FileUtils.mkdir_p(directory)
        File.chmod(options[:chmod], directory)
      end
        
        # Partitioner that takes an id, pads it up to 12 digits then splits
        # that into 4 folders deep, each 3 digits long.
        # 
        # i.e.
        #   000/000/012/139
        # 
        # Scheme allows for 1000 billion files while never storing more than
        # 1000 files in a single folder.
        #
        # Can overwrite this method to provide your own partitioning scheme.
        def partition(id)
          # TODO: there's probably some fancy 1-line way to do this...
          padded = ("0"*(12-id.to_s.size)+id.to_s).split('')
          File.join(*[0, 3, 6, 9].collect{ |i| padded.slice(i, 3).join })
        end
      end
      
      attr_accessor :filename
      attr_accessor :attachment
      
      # TODO: can probably fanagle a way to only pass a reference to the model
      # and not need the filename (or better yet just the filename and 
      # decouple)
      def initialize(attachment, filename)
        @attachment = attachment
        @filename   = filename
      end
      
      # Returns the milton options on the associated attachment.
      def milton_options
        self.attachment.class.milton_options
      end

      # Returns the full path and filename to the file with the given options.
      # If no options are given then returns the path and filename to the
      # original file.
      def path(options={})
        options.empty? ? File.join(dirname, filename) : Derivative.new(filename, options).path
      end
            
      # Returns the full directory path up to the file, w/o the filename.
      def dirname
        File.join(root_path, partitioned_path)
      end
      
      # Returns true if the file exists on the underlying file system.
      def exists?
        File.exist?(path)
      end
      
      # Removes the file from the underlying file system and any derivatives of
      # the file.
      def destroy
        destroy_file
      end
      
      protected
        # Returns the file as a File object opened for reading.
        def file_reference
          File.new(path)
        end
        
        # Returns the partitioned path segment based on the id of the model
        # this file is attached to.
        def partitioned_path
          self.class.partition(self.attachment.id)
        end

        # The full path to the root of where files will be stored on disk.
        def root_path
          milton_options[:file_system_path]
        end

        # Creates the directory this file will be stored in.
        # Also creates the root path where all attachments are stored if it
        # doesn't exist yet.
        def recreate_directory
          self.class.recreate_directory(dirname, milton_options)
        end
        
        # Removes the containing directory from the filesystem (and hence the
        # file and any derivatives)
        def destroy_file
          FileUtils.rm_rf dirname if File.exists?(dirname)
        end
        
        # Returns an array of Derivatives of this AttachableFile.
        def derivatives
          Dir.glob(dirname + '/*').reject{ |filename| filename == self.filename }.collect do |filename|
            Derivative.from_filename(filename)
          end
        end
    end

    # Represents a file created on the file system that is a derivative of the
    # one referenced by the model, i.e. a thumbnail of an image, or a transcode
    # of a video.
    # 
    # Provides a container for options and a uniform API to dealing with
    # passing options for the creation of derivatives.
    # 
    # Files created as derivatives have their creation options appended into
    # their filenames so it can be checked later if a file w/ the given
    # options already exists (so as not to create it again).
    #
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

        # Given a filename (presumably with options embedded in it) parses out
        # the options and returns them as a hash.
        def extract_options_from(filename)
          File.basename(filename, File.extname(filename))[(filename.rindex(AttachableFile.options[:separator]) + 1)..-1]
        end
        
        # Creates a new Derivative from the given filename by extracting the
        # options.
        def from_filename(filename)
          Derivative.new(filename, options_from(extract_options_from(filename)))
        end
      end
      
      # Instantiate a new Derivative, takes a reference to the AttachableFile
      # (or specialization class) that this will be a derivative of, and a hash
      # of the options defining the derivative.
      def initialize(file, options)
        @file    = file
        @options = options
      end
      
      # The resulting filename of this Derivative with embedded options.
      def filename
        filename = @file.path
        append   = options.collect{ |k, v| "#{k}=#{v}" }.sort.join('_')
        
        File.basename(filename, File.extname(filename)) + 
        (append.blank? ? '' : "#{@file.milton_options[:separator]}#{append}") + 
        File.extname(filename)
      end
      
      # The full path and filename to this Derivative.
      def path
        File.join(@file.dirname, filename)
      end
      
      # Returns true if the file resulting from this Derivative exists.
      def exists?
        File.exists?(path)
      end
    end
  end
end
