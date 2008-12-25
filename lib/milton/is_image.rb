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
      end
    end
  end
end