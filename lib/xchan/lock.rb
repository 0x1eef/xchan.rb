# frozen_string_literal: true

##
# {Chan::Lock Chan::Lock} is responsible for synchronizing read and write
# operations on a channel through an exclusive lock that only one
# process can hold at a given time.
class Chan::Lock
  require "lockf"
  require "tempfile"

  ##
  # @return [Chan::Lock]
  #  Returns an instance of {Chan::Lock Chan::Lock}.
  def initialize
    @f = Tempfile.new("xchan-lock_file").tap(&:unlink)
  end

  ##
  # Obtains an exclusive lock. <br>
  # This method blocks until a lock can be obtained.
  #
  # @raise [SystemCallError]
  #  Might raise a number of Errno exceptions.
  #
  # @return [Integer]
  #  Returns 0 on success.
  def obtain
    @f.lockf(File::F_LOCK, 0)
  end

  ##
  # Releases an exclusive lock.
  #
  # @raise [SystemCallError]
  #  Might raise a number of Errno exceptions.
  #
  # @return [Integer]
  #  Returns 0 on success.
  def release
    @f.lockf(File::F_ULOCK, 0)
  end

  ##
  # @return [Boolean]
  #  Returns true when an exclusive lock is held by another process.
  def locked?
    @f.lockf(File::F_TEST, 0)
    false
  rescue Errno::EACCES
    true
  end

  ##
  #  Closes the underlying IO that's used to implement an exclusive
  #  lock.
  #
  # @return [void]
  def close
    @f.close
  end
end
