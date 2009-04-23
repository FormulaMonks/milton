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
        def extract_options_from(filename, options)
          File.basename(filename, File.extname(filename))[(filename.rindex(options[:separator]) + 1)..-1]
        end
        
        # Creates a new Derivative from the given filename by extracting the
        # options.
        def from_filename(filename)
          Derivative.new(filename, options_from(extract_options_from(filename)))
        end
      end

      attr_reader :options
  
      # Instantiate a new Derivative:
      # * +source+: a reference to the Storage::StoredFile this will be a Derivative of
      # * +options+: options to generate the Derivative using
      def initialize(source, options={})
        @source  = source
        @options = options.is_a?(String) ? self.class.options_from(options) : options
      end
  
      # The resulting filename of this Derivative with embedded options.
      def filename
        filename  = @source.path
        append    = options[:name] ? options[:name] : options.collect{ |k, v| "#{k}=#{v}" }.sort.join('_')
        extension = File.extname(filename)
    
        File.basename(filename, extension) + (append.blank? ? '' : "#{@source.options[:separator]}#{append}") + extension
      end
  
      # The full path and filename to this Derivative.
      def path
        file.path
      end
      
      # Returns true if this Derivative has already been generated and stored.
      def exists?
        file.exists?
      end
      
      protected
      
      def postprocessing?
        @source.options[:postprocessing]
      end
      
      def file
        @file ||= @source.copy(filename)
      end
    end
  end
end