module Milton
  module Storage
    class StoredFile
      class << self
        # Sanitizes the given filename, removes pathnames and the special chars
        # needed for options seperation for derivatives
        def sanitize_filename(filename, options)
          File.basename(filename, File.extname(filename)).gsub(/^.*(\\|\/)/, '').
            gsub(/[^\w]|#{Regexp.escape(options[:separator])}/, options[:replacement]).
            strip + File.extname(filename)
        end
        
        def create(filename, id, source, options)
          returning new(filename, id, options) do |file|
            file.store(source)
          end
        end
        
        # Returns the adapter class specified by the given type (by naming
        # convention)
        # 
        #     Storage::StoredFile.adapter(:s3) => Storage::S3File
        #     Storage::StoredFile.adapter(:disk) => Storage::DiskFile
        # 
        def adapter(type)
          "Milton::Storage::#{type.to_s.classify}File".constantize
        end
      end
              
      attr_accessor :filename, :id, :options

      def initialize(filename, id, options)
        self.filename = filename
        self.id       = id
        self.options  = options
      end
      
      # Creates a clone of this StoredFile of the same type with the same id
      # and options but using the given filename. Doesn't actually do any
      # copying of the underlying file data.
      def clone(filename)
        self.class.new(filename, self.id, self.options)
      end
    end
  end
end
