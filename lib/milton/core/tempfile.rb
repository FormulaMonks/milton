require 'tempfile'

module Milton
  # For lack of a better name, a MiltonTempfile adds some helpful
  # functionality to Ruby's Tempfile
  class Tempfile < ::Tempfile
    class << self
      def create(data_or_path, tempfile_path)
        FileUtils.mkdir_p(tempfile_path) unless File.exists?(tempfile_path)
    
        tempfile = new(basename, tempfile_path)
    
        if data_or_path.is_a?(StringIO)
          tempfile.binmode
          tempfile.write data_or_path.read
          tempfile.close
        else
          tempfile.close
          FileUtils.cp((data_or_path.respond_to?(:path) ? data_or_path.path : data_or_path), tempfile.path)
        end
    
        tempfile
      end
    
      def basename
        "#{rand(Time.now.to_i)}"
      end
    
      def filename(extension)
        "#{basename}.#{extension}"
      end
    
      def path(tempfile_path, extension)
        File.join(tempfile_path, filename(extension))
      end
      
      # Simple helper that returns a path to a tempfile with a uniquely
      # generated basename and same extension as the given source.
      def from(source)
        filename(Milton::File.extension(source))
      end
    end
  end
end
