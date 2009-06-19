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
          [ key.to_sym, value || true ] # nothing on RHS of = means it's a boolean true
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
      
      def process(source, options={}, settings={})
        returning(derivative = new(source, options, settings)) do
          derivative.process unless derivative.exists?
        end
      end
      
      def factory(type, source, options={}, settings={})
        begin
          klass = "Milton::#{type.to_s.classify}".constantize
        rescue NameError
          begin
            require "milton/derivatives/#{type.to_s}"
          rescue MissingSourceFile => e
            raise MissingSourceFile.new("#{e.message} (milton: couldn't find the processor '#{type}' you were trying to load)", e.path)
          end
          klass = "Milton::#{type.to_s.classify}".constantize
        end
        
        klass.new(source, options, settings)
      end
    end

    attr_reader :options, :settings

    # Instantiate a new Derivative:
    # * +source+: a reference to the Storage::StoredFile this will be a Derivative of
    # * +options+: options to generate the Derivative using
    # * +settings+: settings about how to create Derivatives
    def initialize(source, options={}, settings={})
      @source   = source
      @options  = options.is_a?(String) ? self.class.options_from(options) : options
      @settings = settings
    end

    # The resulting filename of this Derivative with embedded options.
    def filename
      # ignore false booleans and don't output =true for true booleans,
      # otherwise just k=v
      append    = options.reject{ |k, v| v.is_a?(FalseClass) }.collect { |k, v| v === true ? k.to_s : "#{k}=#{v}" }.sort.join('_')
      extension = File.extname(@source.path)
      File.basename(@source.path, extension) + (append.blank? ? '' : "#{settings[:separator]}#{append}") + extension
    end

    # The full path and filename to this Derivative.
    def path
      file.path
    end
    
    # Returns true if this Derivative has already been generated and stored.
    def exists?
      file.exists?
    end
    
    # Overwrite this to provide your derivatives processing.
    def process;end;
    
    # Convenience method, only runs process if the given condition is true.
    # Returns the derivative so it's chainable.
    def process_if(condition)
      process if condition && !exists?
      return self
    end
    
    # Returns the StoredFile which represents the Derivative (which is a copy
    # of the source w/ a different filename).
    def file
      @file ||= @source.clone(filename)
    end
  end
end
