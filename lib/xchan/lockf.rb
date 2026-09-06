# frozen_string_literal: true

require "fiddle/import"
require "tempfile"

##
# @private
# {Chan::Lockf Chan::Lockf} provides an object-oriented
# [lockf(3)](https://man.freebsd.org/cgi/man.cgi?query=lockf&sektion=3)
# interface backed by Fiddle from the standard library.
# It supersedes the runtime dependency on the lockf.rb gem.
class Chan::Lockf
  module LibC
    extend Fiddle::Importer
    dlload Fiddle.dlopen(nil)
    extern "int lockf(int fd, int cmd, int size)"
  end
  private_constant :LibC

  F_ULOCK = 0x0
  F_LOCK  = 0x1
  F_TLOCK = 0x2
  F_TEST  = 0x3

  ##
  # @return [<#fileno>]
  #  Returns a file handle
  attr_reader :file

  ##
  # @param [<#fileno>] file
  # @param [Integer] size
  # @return [Chan::Lockf]
  #  Returns an instance of {Chan::Lockf Chan::Lockf}
  def initialize(file, size = 0)
    @file = file
    @size = size
  end

  ##
  # Acquire lock (blocking)
  # @raise [SystemCallError]
  #  Might raise a subclass of SystemCallError
  # @return [Boolean]
  #  Returns true when successful
  def lock = try(F_LOCK)

  ##
  # Acquire lock (non-blocking)
  # @raise [SystemCallError]
  #  Might raise a subclass of SystemCallError
  # @return [Boolean]
  #  Returns true when successful
  def lock_nonblock = try(F_TLOCK)

  ##
  # Release lock
  # @raise [SystemCallError]
  #  Might raise a subclass of SystemCallError
  # @return [Boolean]
  #  Returns true when successful
  def release = try(F_ULOCK)

  ##
  # @return [Boolean]
  #  Returns true when lock can be acquired
  def lockable?
    try(F_TEST)
    true
  rescue Errno::EACCES, Errno::EAGAIN, Errno::EWOULDBLOCK
    false
  end

  ##
  # Closes {Chan::Lockf#file Chan::Lockf#file}
  # @return [void]
  def close
    @file.respond_to?(:close) ? @file.close : nil
  end

  private

  def try(function, attempts: 3)
    fileno = @file.respond_to?(:fileno) ? @file.fileno : @file
    LibC.lockf(fileno, function, @size).zero? ||
      raise(SystemCallError.new("lockf", Fiddle.last_error))
  rescue Errno::EINTR => ex
    attempts -= 1
    (attempts.zero? ? raise(ex) : retry)
  end
end
