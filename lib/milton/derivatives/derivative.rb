module Citrusbyte
  module Milton
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

      attr_reader :options
  
      # Instantiate a new Derivative:
      # * +file+: a reference to the Storage::File this will be a Derivative of
      # * +options+: [optional] options to generate the Derivative using
      def initialize(file, options={})
        @file    = file
        @options = options.is_a?(String) ? self.class.options_from(options) : options
      end
  
      # The resulting filename of this Derivative with embedded options.
      def filename
        filename  = @file.path
        append    = options.collect{ |k, v| "#{k}=#{v}" }.sort.join('_')
        extension = File.extname(filename)
    
        File.basename(filename, extension) + (append.blank? ? '' : "#{@file.options[:separator]}#{append}") + extension
      end
  
      # The full path and filename to this Derivative.
      def path
        File.join(dirname, filename)
      end
      
      def to_s
        path  
      end
  
      # Returns true if the file resulting from this Derivative exists.
      def exists?
        File.exists?(path)
      end
      
      protected
      
      def dirname
        File.dirname(@file.path)
      end
    end
  end
end