# frozen_string_literal: true

module Chan
  require_relative "xchan/version"
  require_relative "xchan/unix_socket"
  require_relative "xchan/null_lock"
  require_relative "xchan/tempfile"

  WaitReadable = Class.new(IO::EAGAINWaitReadable)
  WaitWritable = Class.new(IO::EAGAINWaitWritable)
  WaitLockable = Class.new(Errno::EWOULDBLOCK)

  ##
  # Coerces an object to a string for a
  # channel communicating in raw strings
  # (in other words: without serialization)
  #
  # @example
  #   ch = xchan(:pure)
  #   fork { ch.send "Hello world" }
  #   Process.wait
  #   puts ch.recv
  Pure = Class.new do
    def self.dump(str) = str.to_s
    def self.load(str) = str.to_s
  end

  ##
  # Returns an unlinked {Chan::Tempfile Chan::Tempfile} object
  # that can be read from, and written to by the process that
  # created it, inclusive of its child processes, but not of
  # processes other than that.
  #
  # @param [String] basename
  #  Basename of the temporary file
  # @param [String] tmpdir
  #  Parent directory of the temporary file
  # @return [Chan::Tempfile]
  #  Returns an instance of {Chan::Tempfile Chan::Tempfile}
  def self.temporary_file(basename, tmpdir: Dir.tmpdir)
    Chan::Tempfile.new(basename, tmpdir, perm: 0).tap(&:unlink)
  end

  ##
  # @return [Hash<Symbol, Proc>]
  #  Returns the default serializers
  def self.serializers
    {
      pure: lambda { Pure },
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

  ##
  # @return [Hash<Symbol, Proc>]
  #  Returns the default locks
  def self.locks
    {
      null: lambda { |_tmpdir| Chan::NullLock },
      file: lambda { |tmpdir| Lock::File.new Chan.temporary_file(%w[xchan lock], tmpdir:) }
    }
  end
end

module Kernel
  ##
  # @example
  #   ch = xchan
  #   ch.send([1,2,3])
  #   ch.recv.pop # => 3
  #   ch.close
  # @param serializer (see Chan::UNIXSocket#initialize)
  # @param sock (see Chan::UNIXSocket#initialize)
  # @param tmpdir (see Chan::UNIXSocket#initialize)
  # @param lock (see Chan::UNIXSocket#initialize)
  # @return (see Chan::UNIXSocket#initialize)
  def xchan(s, ...)
    Chan::UNIXSocket.new(s, ...)
  end
end
