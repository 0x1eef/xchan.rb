# frozen_string_literal: true

module Chan
  require_relative "xchan/version"
  require_relative "xchan/unix_socket"
  require_relative "xchan/tempfile"
  require_relative "xchan/mixin"

  WaitReadable = Class.new(IO::EAGAINWaitReadable)
  WaitWritable = Class.new(IO::EAGAINWaitWritable)
  WaitLockable = Class.new(Errno::EWOULDBLOCK)
  Plain = Class.new do
    def self.dump(str) = str.to_s
    def self.load(str) = str.to_s
  end

  ##
  # Returns an unlinked {Chan::Tempfile Chan::Tempfile} object
  # that can be read from, and written to by the process that
  # created it, inclusive of its child processes, but not by
  # other processes.
  #
  # @param [String] basename
  #  Basename of the temporary file.
  #
  # @param [String] tmpdir
  #  Parent directory of the temporary file.
  #
  # @return [Chan::Tempfile]
  #  Returns an instance of {Chan::Tempfile Chan::Tempfile}.
  def self.temporary_file(basename, tmpdir: Dir.tmpdir)
    Chan::Tempfile.new(basename, tmpdir, perm: 0).tap(&:unlink)
  end

  def self.serializers
    {
      plain: lambda { Plain },
      marshal: lambda { Marshal },
      json: lambda {
        require "json" unless defined?(JSON)
        JSON
      },
      yaml: lambda {
        require "yaml" unless defined?(YAML)
        YAML
      }
    }
  end
end

class Object
  include Chan::Mixin
end
