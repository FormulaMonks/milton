module Citrusbyte
  module Milton
    module IsImage
      def self.included(base)
        base.extend IsMethods
      end

      module IsMethods
        # Stupid little helper for defining something as an image, this used to
        # have more functionality, it's just being kept around because it will
        # probably be useful in the future. For the time being it just allows
        # you to do:
        #
        # class Image < ActiveRecord::Base
        #   is_image
        # end
        #
        # rather than:
        #
        # class Image < ActiveRecord::Base
        #   is_uploadable
        #   is_resizeable
        # end
        def is_image(options={})
          is_uploadable options
          is_resizeable options
        end
      end
    end
  end
end