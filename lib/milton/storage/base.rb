module Citrusbyte
  module Milton
    module Storage
      class Base
        class << self
          # Sanitizes the given filename, removes pathnames and the special chars
          # needed for options seperation for derivatives
          def sanitize_filename(filename, options)
            File.basename(filename, File.extname(filename)).gsub(/^.*(\\|\/)/, '').
              gsub(/[^\w]|#{Regexp.escape(options[:separator])}/, options[:replacement]).
              strip + File.extname(filename)
          end
        end
                
        attr_accessor :filename, :id, :options

        # options...
        #   :file_system_path
        #   :chmod
        def initialize(filename, options)
          self.filename = filename
          self.id       = options.delete(:id)
          self.options  = options
        end
      end
    end
  end
end
