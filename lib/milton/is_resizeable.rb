module Citrusbyte
  module Milton    
    module IsResizeable
      def self.included(base)
        base.extend IsMethods
      end

      module IsMethods
        def is_resizeable(options={})
          ensure_attachment_methods options
          
          require_column 'content_type', "Milton's is_resizeable requires a content_type column on #{class_name} table"

          self.milton_options.merge!(options)

          extend  Citrusbyte::Milton::IsResizeable::ClassMethods
          include Citrusbyte::Milton::IsResizeable::InstanceMethods
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        # Returns the content_type of this attachment, tries to determine it if
        # hasn't been determined yet or is not saved to the database
        def content_type
          return self[:content_type] unless self[:content_type].blank?
          self.content_type = file_reference.mime_type? if file_reference.respond_to?(:mime_type?)
        end
                
        # Sets the content type to the given type
        def content_type=(type)
          write_attribute :content_type, type.to_s.strip
        end
                
        protected
          def attached_file
            @attached_file ||= ResizeableFile.new(self, filename)
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
            raise Citrusbyte::Milton::MissingFileError.new("Could not identify #{path} as an image, does the file exist?") unless `identify #{path}` =~ /.*? (\d+)x(\d+)\+\d+\+\d+/
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
    
    class ResizeableFile < AttachableFile
      class << self
        # Returns the given size as an array of two integers, width first. Can
        # handle:
        #
        # A fixnum argument, which results in a square sizing:
        #   parse_size(40) => [40, 40]
        # An Array argument, which is simply returned:
        #   parse_size([40, 40]) => [40, 40]
        # A String argument, which is split on 'x' and converted:
        #   parse_size("40x40") => [40, 40]
        def parse_size(size)
          case size.class.to_s
          when "Fixnum" then [size.to_i, size.to_i]
          when "Array"  then size
          when "String" then size.split('x').collect(&:to_i)
          end
        end
      end
      
      def initialize(attachment, filename)
        super attachment, filename
      end
      
      def path(options={})
        options = Derivative.options_from(options) if options.is_a?(String)
        return super if options.empty?
        
        derivative = Derivative.new(self, options)
        resize(derivative) unless derivative.exists?
        derivative.path
      end
      
      protected
        # For speed, any derivatives less than 640-wide are made from a 
        # 640-wide version of the image (so you're not generating tiny
        # thumbnails from an 8-megapixel upload)
        def presize_options(derivative)
          image.width > 640 && IsResizeable::Image.from_geometry(derivative.options[:size]).width < 640 ? { :size => '640x' } : {}
        end
      
        def image
          @image ||= IsResizeable::Image.from_path(path)
        end
      
        def resize(derivative)
          raise "target size must be specified for resizing" unless derivative.options.has_key?(:size)
          
          if derivative.options[:crop]
            crop = IsResizeable::CropCalculator.new(image, IsResizeable::Image.from_geometry(derivative.options[:size]))
            size = crop.resizing_geometry
            conversion_options = %Q(-gravity #{crop.gravity} -crop #{crop.cropping_geometry})
          end

          system %Q(convert -geometry #{size || derivative.options[:size]} #{ResizeableFile.new(@attachment, @attachment.filename).path(presize_options(derivative))} #{conversion_options || ''} +repage "#{derivative.path}")
        end
    end
  end
end
