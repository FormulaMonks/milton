require 'milton/derivatives/thumbnail/image'
require 'milton/derivatives/thumbnail/crop_calculator'

module Milton
  class Thumbnail < Derivative
    def process
      raise "target size must be specified for resizing" unless options.has_key?(:size)
      
      temp_dst = File.join(settings[:tempfile_path], Milton::Tempfile.from(@source.filename))
      temp_src = File.join(settings[:tempfile_path], Milton::Tempfile.from(@source.filename))
      
      @source.copy(temp_src)
      image = Image.from_path(temp_src)
      
      # TODO: this really only makes sense for processing recipes, reimplement
      # once it's setup to build all derivatives then push to storage
      # 
      # For speed, any derivatives less than 640-wide are made from a 
      # 640-wide version of the image (so you're not generating tiny
      # thumbnails from an 8-megapixel upload)
      # source = if image.width > 640 && Image.from_geometry(options[:size]).width < 640
      #   Thumbnail.process(@source, { :size => '640x' }, settings).file
      # else
      #   @source
      # end
      
      if options[:crop]
        crop = CropCalculator.new(image, Image.from_geometry(options[:size]))
        size = crop.resizing_geometry
        conversion_options = %Q(-gravity #{crop.gravity} -crop #{crop.cropping_geometry})
      end
      
      Milton.syscall!(%Q{convert #{temp_src} -geometry #{size || options[:size]} #{conversion_options || ''} +repage "#{temp_dst}"})
    
      # TODO: raise if the store fails
      file.store(temp_dst)
    end
  end
end
