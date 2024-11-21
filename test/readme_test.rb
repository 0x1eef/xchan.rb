# frozen_string_literal: true

require_relative "setup"
require "test-cmd"

class Chan::ReadmeTest < Test::Unit::TestCase
  def test_serialization_1_serializers
    assert_equal "5 + 7 = 12\n",
                 cmd("ruby", readme_example("serialization/1_serializers.rb")).stdout
  end

  def test_read_operations_1_blocking_read
    r = 'Send a random number \(from parent process\)\s*' \
        'Received random number \(child process\): \d+'
    assert_match Regexp.new(r),
                 cmd("ruby", readme_example("read_operations/1_blocking_read.rb"))
                   .stdout
                   .tr("\n", " ")
  end

  def test_write_operations_2_non_blocking_write
    assert_equal ["Blocked - free send buffer\n"],
                 cmd("ruby", readme_example("write_operations/2_nonblocking_write.rb"))
                   .stdout
                   .each_line
                   .uniq
  end

  def test_socket_2_options
    r = 'The read buffer can contain a maximum of: \d{1,7} bytes.\s*' \
        'The maximum size of a single message is: \d{1,7} bytes.\s*'
    assert_match Regexp.new(r),
                 cmd("ruby", readme_example("socket/1_options.rb"))
                   .stdout
                   .tr("\n", " ")
  end

  private

  def readme_example(path)
    dir = File.join(Dir.getwd, "share", "xchan.rb", "examples")
    File.join(dir, path)
  end
end
