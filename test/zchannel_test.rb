require_relative 'setup'
class ZChannelTest < Minitest::Test
  def setup
    @chan = ZChannel.unix Object.const_get(ENV["SERIALIZER"] || "Marshal")
  end

  def teardown
    @chan.close unless @chan.closed?
  end

  def test_send_and_recv_with_NULL_BYTE_in_message
    @chan.send ["hello#{null_byte}"]
    assert_equal ["hello#{null_byte}"], @chan.recv
  end

  def test_blocking_recv
    assert_raises Timeout::Error do
      Timeout.timeout(1) { @chan.recv }
    end
  end

  def test_timeout_on_recv
    assert_raises ZChannel::TimeoutError do
      @chan.recv! 1
    end
  end

  def test_last_msg_after_read
    @chan.send [42]
    @chan.recv
    assert_equal [42], @chan.last_msg
  end

  def test_fork
    pid = fork do
      @chan.send [42]
    end
    Process.wait pid
    assert_equal [42], @chan.recv
  end

  def test_last_msg
    @chan.send %w(a)
    @chan.send %w(b)
    assert_equal %w(b), @chan.last_msg
  end

  def test_last_msg_cache
    @chan.send %w(a)
    2.times { assert_equal %w(a), @chan.last_msg }
    @chan.close
    assert_equal %w(a), @chan.last_msg
  end

  def test_bust_last_msg_cache
    @chan.send %w(a)
    assert_equal %w(a), @chan.last_msg
    @chan.send %w(b)
    2.times { assert_equal %w(b), @chan.last_msg }
  end

  def test_send_on_closed_channel
    @chan.close
    assert_raises IOError do
      @chan.send %w(a)
    end
  end

  def test_recv_on_closed_channel
    @chan.close
    assert_raises IOError do
      @chan.recv
    end
  end

  def test_queued_messages
    @chan.send %w(a)
    @chan.send %w(b)
    assert_equal %w(a), @chan.recv
    assert_equal %w(b), @chan.recv
  end

  def test_readable_on_populated_channel
    @chan.send %w(a)
    @chan.send %w(b)
    assert @chan.readable?
  end

  def test_readable_on_empty_channel
    @chan.send %w(42)
    @chan.recv # discard
    refute @chan.readable?
  end

  def test_readable_on_closed_channel
    @chan.close
    refute @chan.readable?
  end

  private def null_byte
    ZChannel::UNIXSocket::NULL_BYTE
  end
end
