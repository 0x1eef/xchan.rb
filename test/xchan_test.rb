# frozen_string_literal: true

require_relative "setup"

class Chan::Test < Test::Unit::TestCase
  def setup
    @ch = xchan ENV.fetch("SERIALIZER", "marshal").to_sym
  end

  def teardown
    ch.close unless ch.closed?
  end

  private

  def ch
    @ch
  end

  def object
    case ENV["SERIALIZER"]
    when "plain" then "xchan"
    else %w[xchan]
    end
  end

  def object_size
    ch.serializer.dump(object).bytesize
  end
end

##
# Chan::UNIXSocket#send
class Chan::SendTest < Chan::Test
  def test_send_return_value
    assert_equal object_size, ch.send(object)
  end

  def test_send_with_multiple_objects
    3.times { |i| Process.wait fork { ch.send(object) } }
    assert_equal [object, object, object], 3.times.map { ch.recv }
  end

  def test_send_race_condition
    pids = 4.times.map { fork { exit(ch.recv.to_i) } }
    sleep(0.1 * 4)
    pids.each.with_index(1) { ch.send(object) }
    assert_equal pids.map { 42 }, pids.map { Process.wait2(_1).last.exitstatus }
  end

  def object
    42.to_s
  end
end

##
# Chan::UNIXSocket#recv
class Chan::RecvTest < Chan::Test
  include Timeout

  def test_recv_with_null_byte
    ch.send(object.dup << "\x00")
    assert_equal object.dup << "\x00", ch.recv
  end

  def test_that_recv_blocks
    assert_raises(Timeout::Error) do
      timeout(0.3) { ch.recv }
    end
  end
end

##
# Chan::UNIXSocket#recv_nonblock
class Chan::RecvNonBlockTest < Chan::Test
  include Timeout

  def test_recv_nonblock_with_empty_channel
    assert_raise(Chan::WaitReadable) { ch.recv_nonblock }
  end

  def test_recv_nonblock_with_a_lock
    ch.instance_variable_get(:@lock).lock
    pid = fork do
      ch.recv_nonblock
      exit(1)
    rescue Chan::WaitLockable
      exit(0)
    end
    Process.wait(pid)
    assert_equal 0, $?.exitstatus
  end
end

##
# Chan::UNIXSocket#empty?
class Chan::EmptyTest < Chan::Test
  def test_empty_with_empty_channel
    assert_equal true, ch.empty?
  end

  def test_empty_with_one_object
    ch.send(object)
    assert_equal false, ch.empty?
  end

  def test_empty_after_recv
    ch.send(object)
    ch.recv
    assert_equal true, ch.empty?
  end

  def test_empty_on_closed_channel
    ch.send(object)
    ch.close
    assert_equal true, ch.empty?
  end
end

##
# Chan::UNIXSocket#size
class Chan::SizeTest < Chan::Test
  def test_size_with_one_object
    ch.send(object)
    assert_equal 1, ch.size
  end

  def test_size_with_two_objects
    2.times { ch.send(object) }
    assert_equal 2, ch.size
  end

  def test_size_after_recv
    ch.send(object)
    ch.recv
    assert_equal 0, ch.size
  end
end

##
# Chan::UNIXSocket#to_a
class Chan::ToArrayTest < Chan::Test
  def test_to_a_with_splat
    3.times { ch.send(object) }
    assert_equal [object, object, object], splat(*ch)
  end

  def test_to_a_with_last
    3.times { ch.send(object) }
    assert_equal object, ch.to_a.last
  end

  def test_to_a_with_empty_channel
    assert_equal [], ch.to_a
  end

  private

  def splat(*args)
    args
  end
end

##
# Chan::UNIXSocket#bytes_written
class Chan::BytesWrittenTest < Chan::Test
  def test_bytes_written_with_one_object
    Process.wait fork { ch.send(object) }
    assert_equal object_size, ch.bytes_written
  end

  def test_bytes_written_with_two_objects
    2.times { Process.wait fork { ch.send(object) } }
    assert_equal object_size * 2, ch.bytes_written
  end
end

##
# Chan::UNIXSocket#bytes_read
class Chan::BytesReadTest < Chan::Test
  def test_bytes_read_with_one_object
    ch.send(object)
    Process.wait fork { ch.recv }
    assert_equal object_size, ch.bytes_read
  end

  def test_bytes_read_with_two_objects
    2.times { ch.send(object) }
    2.times { Process.wait fork { ch.recv } }
    assert_equal object_size * 2, ch.bytes_read
  end
end
