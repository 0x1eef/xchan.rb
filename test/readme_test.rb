require_relative "setup"
require "test/cmd"

class Chan::ReadmeTest < Test::Unit::TestCase
  include Test::Cmd

  def test_serialization_1_serializers
    assert_equal "Received message: serialized by Marshal\n"*2,
                 readme_example("serialization/1_serializers.rb").stdout
  end

  def test_read_operations_1_blocking_read
    r = 'Send a random number \(from parent process\)\s*' \
        'Received random number \(child process\): \d+'
    assert_match Regexp.new(r),
                 readme_example("read_operations/1_blocking_read.rb").stdout
                                                                     .gsub("\n"," ")
  end

  def test_write_operations_2_non_blocking_write
    assert_equal ["Blocked - free send buffer\n"],
                 readme_example("write_operations/2_nonblocking_write.rb").stdout
                                                                          .each_line
                                                                          .uniq
  end

  private

  def readme_example(path)
    examples_dir = File.join(Dir.getwd, "share", "xchan.rb")
    example = File.join(examples_dir, path)
    cmd "bundle exec ruby #{example}"
  end
end
