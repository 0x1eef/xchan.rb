# frozen_string_literal: true

##
# {Chan::NullLock Chan::NullLock} is a no-op lock that can be used
# instead of the standard file lock when a lock is not needed
#
# @example
#   ch = xchan(:marshal, lock: Chan::NullLock)
#   ch.send([1,2,3])
#   # ..
class Chan::NullLock
  ##
  # @return [void]
  #  This method is a no-op
  def self.lock
  end

  ##
  # @return [void]
  #  This method is a no-op
  def self.lock_nonblock
  end

  ##
  # @return [void]
  #  This method is a no-op
  def self.release
  end

  ##
  # @return [void]
  #  This method is a no-op
  def self.close
  end

  ##
  # @return [void]
  #  This method always returns false
  def self.locked?
    false
  end
end
