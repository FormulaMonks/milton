module Milton
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
        raise Milton::MissingFileError.new("Could not identify #{path} as an image, does the file exist?") unless Milton.syscall("identify #{path}") =~ /.*? (\d+)x(\d+)\+\d+\+\d+/
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
end
