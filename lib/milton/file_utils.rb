module FileUtils
  # mkdir_p that is aware of symbolic links and doesn't try to recreate them
  # if they exist w/in the given list of directories to create
  #
  # this is just a minor change to FileUtils#mkdir_p
  def symlink_aware_mkdir_p(list, options = {})
    fu_check_options options, OPT_TABLE['mkdir_p']
    list = fu_list(list)
    fu_output_message "mkdir -p #{options[:mode] ? ('-m %03o ' % options[:mode]) : ''}#{list.join ' '}" if options[:verbose]
    return *list if options[:noop]

    list.map {|path| path.sub(%r</\z>, '') }.each do |path|
      # optimize for the most common case
      begin
        fu_mkdir path, options[:mode]
        next
      rescue SystemCallError
        next if File.directory?(path) || File.symlink?(path)
      end

      stack = []
      until path == stack.last   # dirname("/")=="/", dirname("C:/")=="C:/"
        stack.push path
        path = File.dirname(path)
      end
      stack.reverse_each do |path|
        begin
          fu_mkdir path, options[:mode]
        rescue SystemCallError => err
          raise unless File.directory?(path) || File.symlink?(path)
        end
      end
    end

    return *list
  end
  module_function :symlink_aware_mkdir_p
end