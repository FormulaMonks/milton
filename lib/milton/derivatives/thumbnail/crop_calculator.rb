module Milton
  class CropCalculator
    attr_reader :original, :target

    # Initializes a new CropCalculator with the two given Images.
    #
    # A CropCalculator is used to calculate the proper zoom/crop dimensions
    # to be passed to ImageMagick's convert method in order to transform
    # the original Image's dimensions into the target Image's dimensions
    # with sensible zoom/cropping.
    def initialize(original, target)
      @original = original
      @target   = target
    end

    # Returns the geometry string to send to ImageMagick's convert -resize
    # argument -- that is, the dimensions that the original Image would
    # need to be resized to in order to result in the given target Image's
    # dimensions with cropping.
    def resizing_geometry
      case
        when original.wider? then "#{resized_width}x#{target.height}"
        when original.square? && target.wider? then "#{target.width}x#{resized_height}"
        when original.square? && !target.wider? then "#{resized_width}x#{target.height}"
        else "#{target.width}x#{resized_height}"
      end
    end

    # The geometry string to send to ImageMagick's convert -crop argument.
    def cropping_geometry
      "#{target.width}x#{target.height}+0+0"
    end

    # The gravity to use for cropping.
    def gravity
      original.wider? ? "center" : "north"
    end

    private

    def resized_width
      (target.height * original.width / original.height).to_i
    end

    def resized_height
      (target.width * original.height / original.width).to_i
    end

    # TODO: this is the old-school cropping w/ coords, need to implement
    # cropping w/ coords using the new system calls
    # def crop_with_coordinates(img, x, y, size, options={})
    #   gravity = options[:gravity] || Magick::NorthGravity
    #   cropped_img = nil
    #   img = Magick::Image.read(img).first unless img.is_a?(Magick::Image)
    #   szx, szy = img.columns, img.rows
    #   sz = self.class.get_size_from_parameter(size)
    #   # logger.info "crop_with_coordinates: img.crop!(#{x}, #{y}, #{sz[0]}, #{sz[1]}, true)"
    #   # cropped_img = img.resize!(sz[0], sz[1]) # EEEEEK
    #   cropped_img = img.crop!(x, y, szx, szy, true)
    #   cropped_img.crop_resized!(sz[0], sz[1], gravity) # EEEEEK
    #   self.temp_path = write_to_temp_file(cropped_img.to_blob)
    # end
  end
end
