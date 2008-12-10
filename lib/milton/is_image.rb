module Citrusbyte
  module Milton
    module IsImage
      def self.included(base)
        base.extend IsMethods
      end

      module IsMethods
        def is_image(options={})
          is_uploadable options
          is_resizeable options
          include InstanceMethods
        end
      end

      module InstanceMethods
        def to_s
          self.public_filename
        end
      end
    end
  end
end