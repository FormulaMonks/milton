module Citrusbyte
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
          
          def create(filename, source, options)
            file = new(filename, options)
            file.store(source)
            file
          end
          
          # Returns the adapter class specified by the given type (by naming
          # convention)
          # 
          #     Storage::StoredFile.adapter(:s3) => Storage::S3File
          #     Storage::StoredFile.adapter(:disk) => Storage::DiskFile
          # 
          def adapter(type)
            "Citrusbyte::Milton::Storage::#{type.to_s.classify}File".constantize
          end
        end
                
        attr_accessor :filename, :id, :options

        # TODO: id should be another param, not given in options
        def initialize(filename, options)
          self.filename = filename
          self.id       = options.delete(:id)
          self.options  = options
        end
      end
    end
  end
end
