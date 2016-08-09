require_relative 'setup'
class ZChannelTest < Test::Unit::TestCase
  def setup
    serializer = Object.const_get ENV["SERIALIZER"] || "Marshal"
    @channel = ZChannel.unix serializer
  end

  def teardown
    @channel.close unless @channel.closed?
  end

  def test_blocking_get
    assert_raises Timeout::Error do
      Timeout.timeout(1) { @channel.get }
    end
  end

  def test_timeout_on_get
    assert_raises ZChannel::TimeoutError do
      @channel.get! 1
    end
  end

  def test_last_msg_after_read
    @channel.put [42]
    @channel.get
    assert_equal [42], @channel.last_msg
  end

  def test_fork
    pid = fork do
      @channel.put [42]
    end
    Process.wait pid
    assert_equal [42], @channel.get
  end

  def test_last_msg
    @channel.put %w(a)
    @channel.put %w(b)
    assert_equal %w(b), @channel.last_msg
  end

  def test_last_msg_cache
    @channel.put %w(a)
    2.times { assert_equal %w(a), @channel.last_msg }
    @channel.close
    assert_equal %w(a), @channel.last_msg
  end

  def test_bust_last_msg_cache
    @channel.put %w(a)
    assert_equal %w(a), @channel.last_msg
    @channel.put %w(b)
    2.times { assert_equal %w(b), @channel.last_msg }
  end

  def test_put_on_closed_channel
    @channel.close
    assert_raises IOError do
      @channel.put %w(a)
    end
  end

  def test_get_on_closed_channel
    @channel.close
    assert_raises IOError do
      @channel.get
    end
  end

  def test_queued_messages
    @channel.put %w(a)
    @channel.put %w(b)
    assert_equal %w(a), @channel.get
    assert_equal %w(b), @channel.get
  end

  def test_readable_on_populated_channel
    @channel.put %w(a)
    @channel.put %w(b)
    assert @channel.readable?
  end

  def test_readable_on_empty_channel
    @channel.put %w(42)
    @channel.get # discard
    refute @channel.readable?
  end

  def test_readable_on_closed_channel
    @channel.close
    refute @channel.readable?
  end
end
