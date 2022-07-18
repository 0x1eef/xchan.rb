# frozen_string_literal: true

##
# The {Chan::Lock} class is responsible for synchronizing read
# and write operations on a channel. This class is used to obtain
# an exclusive lock that only one process may hold at a given time -
# other processes have to wait before obtaining a lock.
class Chan::Lock
  require "lockf"
  require "tempfile"

  def initialize
    @f = Tempfile.new("xchan-lock_file").tap(&:unlink)
  end

  def obtain
    @f.lockf(File::F_LOCK, 0)
  end

  def release
    @f.lockf(File::F_ULOCK, 0)
  end

  def close
    @f.close
  end
end
