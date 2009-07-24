require 'milton/attachment'
require 'milton/core/tempfile'
require 'milton/core/file'

module Milton
  # Raised when a file which was expected to exist appears not to exist
  class MissingFileError < StandardError;end;
  class SyscallFailedError < RuntimeError;end;

  # Some definitions for file semantics used throughout Milton, understanding
  # this will make understanding the code a bit easier and avoid ambiguity:
  #
  # path:
  #   the full path to a file or directory in the filesystem
  #     /var/log/apache2 or /var/log/apache2/access.log
  #   can also be defined as:
  #     path == dirname + filename
  #     path == dirname + basename + extension
  #
  # dirname:
  #   the directory portion of the path to a file or directory, all the chars
  #   up to the final /
  #     /var/log/apache2            => /var/log
  #     /var/log/apache2/           => /var/log/apache2
  #     /var/log/apache2/access.log => /var/log/apache2
  #
  # basename:
  #   the portion of a filename *with no extension* (ruby's "basename" may or
  #   may not have an extension), all the chars after the last / and before
  #   the last .
  #     /var/log/apache2                 => apache2
  #     /var/log/apache2/                => nil
  #     /var/log/apache2/access.log      => access
  #     /var/log/apache2/access.2008.log => access.2008
  #
  # extension:
  #   the extension portion of a filename w/ no preceding ., all the chars
  #   after the final .
  #     /var/log/apache2                 => nil
  #     /var/log/apache2/                => nil
  #     /var/log/apache2/access.log      => log
  #     /var/log/apache2/access.2008.log => log
  # 
  # filename:
  #   the filename portion of a path w/ extension, all the chars after the
  #   final /
  #     /var/log/apache2                 => apache2
  #     /var/log/apache2/                => nil
  #     /var/log/apache2/access.log      => access.log
  #     /var/log/apache2/access.2008.log => access.2008.log
  #   can also be defined as:
  #     filename == basename + (extension ? '.' + extension : '')
  #
  
  # Gives the filename and line number of the method which called the method
  # that invoked #called_by.
  def called_by
    caller[1].gsub(/.*\/(.*):in (.*)/, "\\1:\\2")
  end
  module_function :called_by
  
  # Writes the given message to the Rails log at the info level. If given an
  # invoker (just a string) it prepends the message with that. If not given
  # an invoker it outputs the filename and line number which called #log.
  def log(message, invoker=nil)
    invoker ||= Milton.called_by
    Rails.logger.info("[milton] #{invoker}: #{message}")
  end
  module_function :log

  # Executes the given command, returning the commands output if successful
  # or false if the command failed.
  # Redirects stderr to log/milton.stderr.log in order to examine causes of
  # failure.
  def syscall(command)
    begin
      syscall!(command)
    rescue Milton::SyscallFailedError => e      
      return false
    end
  end
  module_function :syscall
  
  def syscall!(command)
    log("executing #{command}", invoker = Milton.called_by)
    stdout = %x{#{command} 2>>#{File.join(Rails.root, 'log', 'milton.stderr.log')}}
    unless $?.success?
      e = Milton::SyscallFailedError.new(command)
      log("failed to execute " + e.message, invoker)
      raise e
    end
    stdout
  end
  module_function :syscall!
  
  # Wraps +require+ on the given path in a rescue which uses the given
  # message for the resulting LoadError on failure instead of the default
  # one to give the user a better idea of what happened (useful for
  # dynamic +require+)
  def try_require(path, message)
    begin
      require path
    rescue LoadError => e
      raise LoadError.new(message + " (failed to require #{path})") if e.message =~ Regexp.new(path)
      raise e
    end
  end
  module_function :try_require
end

ActiveRecord::Base.extend Milton::Attachment
