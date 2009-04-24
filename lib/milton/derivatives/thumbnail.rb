require 'milton/derivatives/thumbnail/image'
require 'milton/derivatives/thumbnail/crop_calculator'

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
  end
end