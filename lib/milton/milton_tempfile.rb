module Citrusbyte
  module Milton
    # For lack of a better name, a MiltonTempfile adds some helpful
    # functionality to Ruby's Tempfile
    class MiltonTempfile < Tempfile
      class << self
        def create(data_or_path, tempfile_path)
          FileUtils.mkdir_p(tempfile_path) unless File.exists?(tempfile_path)
        
          tempfile = new(filename, tempfile_path)
        
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
        
        def filename
          "#{rand(Time.now.to_i)}"
        end
        
        def path(tempfile_path)
          File.join(tempfile_path, filename)
        end
      end
    end
  end
end