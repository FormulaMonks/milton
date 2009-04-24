module Citrusbyte
  module Milton
    class Thumbnail < Derivative      
      def process
        raise "target size must be specified for resizing" unless options.has_key?(:size)

        destination = Milton::Tempfile.path(settings[:tempfile_path], Milton::File.extension(@source.filename))
        
        # TODO: determine if this is neccessary or was just a problem w/ the
        # way we were calling convert
        # convert can be destructive to the original image in certain failure
        # cases, so copy it to a tempfile first before processing
        # source      = Milton::Tempfile.create(self.source, @source.options[:tempfile_path]).path
        
        if options[:crop]
          crop = CropCalculator.new(image, Image.from_geometry(options[:size]))
          size = crop.resizing_geometry
          conversion_options = %Q(-gravity #{crop.gravity} -crop #{crop.cropping_geometry})
        end
        
        # TODO: raise if the syscall fails
        Milton.syscall(%Q{convert #{source} -geometry #{size || options[:size]} #{conversion_options || ''} +repage "#{destination}"}) 
        
        # TODO: raise if the store fails
        file.store(destination)
      end

      protected
      
      # For speed, any derivatives less than 640-wide are made from a 
      # 640-wide version of the image (so you're not generating tiny
      # thumbnails from an 8-megapixel upload)
      def source
        image.width > 640 && Image.from_geometry(options[:size]).width < 640 ? 
          Thumbnail.process(@source, { :size => '640x' }, settings).path : @source.path
      end
      
      # Returns and memoizes an Image initialized from the file we're making a
      # thumbnail of
      def image
        @image ||= Image.from_path(@source.path)
      end
    end
    
    # Generic view of an "Image", or rather, something with a width and a
    # height we care about =).
    class Image
      attr_accessor :width
      attr_accessor :height

      class << self
        # Instantiates a new image from the given path. Uses ImageMagick's
        # identify method to determine the width and height of the image with
        # the given path and returns a new Image with those dimensions.
        #
        # Raises a MissingFileError if the given path could not be identify'd
        # by ImageMagick (resulting in a height and width).
        def from_path(path)
          raise Citrusbyte::Milton::MissingFileError.new("Could not identify #{path} as an image, does the file exist?") unless Milton.syscall("identify #{path}") =~ /.*? (\d+)x(\d+)\+\d+\+\d+/
          new($1, $2)
        end

        # Instantiates a new image from the given geometry string. A geometry
        # string is just something like 50x40. The first number is the width
        # and the second is the height.
        def from_geometry(geometry)
          new(*(geometry.split("x").collect(&:to_i)))
        end
      end

      # Instantiates a new Image with the given width and height
      def initialize(width=nil, height=nil)
        @width  = width.to_i
        @height = height.to_i
      end
      
      # Returns the larger dimension of the Image
      def larger_dimension
        width > height ? width : height
      end

      # Returns true if the Image is wider than it is tall
      def wider?
        width > height
      end
      
      # Returns true if the Image is square
      def square?
        width == height
      end
    end
  
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
end