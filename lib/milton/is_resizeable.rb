module Citrusbyte
  module Milton
    module IsResizeable
      def self.included(base)
        base.extend IsMethods
      end

      module IsMethods
        def is_resizeable(options={})
          raise "is_resizeable requires a content_type column on #{class_name} table" unless column_names.include?("content_type")
          
          options[:size] ||= {}
          
          ensure_attachment_methods options

          class_inheritable_accessor :resizeable_options
          self.resizeable_options = options
          
          attr_accessor :thumbnail_resize_options

          extend  Citrusbyte::Milton::IsResizeable::ClassMethods
          include Citrusbyte::Milton::IsResizeable::InstanceMethods
          
          alias_method_chain :full_filename, :resizing
        end
      end

      module ClassMethods
        def parse_size(size)
          case size.class.to_s
          when "Fixnum" then [size.to_i, size.to_i]
          when "Array"  then size
          when "String" then size.split('x').collect {|a| a.to_i}
          end
        end
      end

      module InstanceMethods
        def image_filename(options={})
          full_filename(options).gsub(/.*public\/images/, '')
        end

        def full_filename_with_resizing(options={})
          return full_filename_without_resizing if options.empty?
          filename = derivative_filename(options)
          resize(filename, options) unless File.exists?(filename)
          filename
        end
        
        protected
          # For speed, any derivatives less than 640-wide are made from a 
          # 640-wide version of the image (so you're not generating tiny
          # thumbnails from an 8-megapixel upload)
          def presize_options(options)
            self.width > 640 && options[:size].split('x').first.to_i < 640 ? { :size => '640x' } : {}
          end
        
          def resize(filename, options)
            raise "target size must be specified for resizing" unless options.has_key?(:size)

            if options[:crop]
              crop = CropCalculator.new(self, options[:size])
              options[:size] = crop.resizing_geometry
              conversion_options = %Q(-gravity #{crop.gravity} -crop #{crop.cropping_geometry})
            end

            system %Q(convert -geometry #{options[:size]} "#{full_filename(presize_options(options))}" #{conversion_options || ''} +repage "#{filename}").gsub(/\s+/, " ")
          end
      end
    
      class Image
        attr_accessor :width
        attr_accessor :height

        class << self
          def from_filename(filename)
            new($1, $2) if `identify #{self.filename}` =~ /.*? (\d+)x(\d+)\+\d+\+\d+/
          end

          def from_geometry(geometry)
            new(*(string.split("x").collect{ |side| side.to_i }))
          end
        end

        def initialize(width=nil, height=nil)
          @width  = width
          @height = height
        end

        def larger_dimension
          width > height ? width : height
        end

        def wider?
          width > height
        end

        def square?
          width == height
        end
      end    
    
      class CropCalculator
        attr_reader :original, :target

        def initialize(original, target)
          @original = original
          @target   = target
        end

        def resizing_geometry
          case
            when original.wider? then "#{resized_width}x#{target.height}"
            when original.square? && target.wider? then "#{target.width}x#{resized_height}"
            when original.square? && !target.wider? then "#{resized_width}x#{target_height}"
            else "#{target_width}x#{resized_height}"
          end
        end

        def cropping_geometry
          "#{original.width}x#{original.height}+0+0"
        end

        def gravity
          image.wider? ? "center" : "north"
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
end
