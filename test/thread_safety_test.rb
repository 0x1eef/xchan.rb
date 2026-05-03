# frozen_string_literal: true

require "xchan"
require "test/unit"

class ThreadSafetyTest < Test::Unit::TestCase
  ##
  # Without a Mutex wrapping the critical sections in send_nonblock and
  # recv_nonblock, lockf(3) record locks do not provide thread safety
  # because they are per-process (PID-based). Two threads sharing the
  # same channel can both acquire the lock simultaneously, causing the
  # @bytes and @counter tempfiles to be read and written concurrently.
  #
  # This test reproduces the race by having one thread write many
  # messages while another reads them. A mismatch between the byte
  # length recorded by @bytes.push and the actual data read from the
  # socket triggers Marshal.load errors.
  def test_concurrent_send_and_recv
    ch = xchan(:marshal)
    n = 1000
    writer = Thread.new do
      n.times { ch.send("hello") }
    end
    reader = Thread.new do
      count = 0
      n.times do
        ch.recv
        count += 1
      end
      count
    end
    count = [writer, reader].map(&:value).last
    assert_equal n, count
  ensure
    ch.close unless ch.closed?
  end

  def test_concurrent_send_nonblock_and_recv_nonblock
    ch = xchan(:marshal)
    n = 1000
    writer = Thread.new do
      n.times { ch.send("world") }
    end
    reader = Thread.new do
      count = 0
      n.times do
        ch.recv
        count += 1
      end
      count
    end
    count = [writer, reader].map(&:value).last
    assert_equal n, count
  ensure
    ch.close unless ch.closed?
  end
end
