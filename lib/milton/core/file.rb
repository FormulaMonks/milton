begin
  require 'mimetype_fu'
rescue MissingSourceFile
end

module Milton
  class File < ::File
    class << self
      def extension(filename)
        extension = extname(filename)
        extension.slice(1, extension.length-1)
      end
      
      # File respond_to?(:mime_type) is true if mimetype_fu is installed, so
      # this way we always have File.mime_type? available but it favors
      # mimetype_fu's implementation.
      def mime_type?(file)
        ::File.respond_to?(:mime_type?) ? super(file.filename) : file.content_type
      end
    end
  end
end
