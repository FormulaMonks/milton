module Citrusbyte
  module Milton
    class File < ::File
      class << self
        def extension(filename)
          extension = extname(filename)
          extension.slice(1, extension.length-1)
        end
      end
    end
  end
end