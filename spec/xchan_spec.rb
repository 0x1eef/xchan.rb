# frozen_string_literal: true

require_relative "setup"

RSpec.shared_examples "xchan" do |serializer|
  let!(:ch) { xchan(serializer) }

  after do
    ch.close unless ch.closed?
  end

  describe "#send" do
    subject(:payload) { %w[xchan] }
    let(:payload_size) { ch.serializer.dump(payload).bytesize }

    context "when counting the number of bytes sent" do
      subject { ch.send(payload) }
      it { is_expected.to eq(payload_size) }
    end

    context "when there are multiple objects to read" do
      subject { 3.times.map { ch.recv } }
      before { Process.wait fork { 1.upto(3) { ch.send([_1]) } } }
      it { is_expected.to eq([[1], [2], [3]]) }
    end

    context "when a deadlock / race condition can occur" do
      subject do
        pids.map { Process.wait2(_1).last.exitstatus }
      end

      let(:process_count) { 4 }
      let(:delay) { 0.1 }
      let!(:pids) do
        process_count.times.map { fork { exit(ch.recv[0]) } }
      end

      before do
        sleep(delay * process_count)
        pids.each.with_index(1) do
          if _2 % 2 == 0
            sleep(delay)
          end
          ch.send([42])
        end
      end

      it { is_expected.to eq(pids.map { 42 }) }
    end
  end

  describe "#recv" do
    subject { ch.recv }

    context "when reading a null byte" do
      before { ch.send(["nullbyte\x00"]) }
      it { is_expected.to eq(["nullbyte\x00"]) }
    end

    context "when a read blocks" do
      subject(:recv) { timeout(0.1) { ch.recv } }
      include Timeout
      it { expect { recv }.to raise_error(Timeout::Error) }
    end
  end

  describe "#recv_nonblock" do
    subject(:recv_nonblock) { ch.recv_nonblock }
    let(:delay) { 0.5 }

    context "when a channel is empty" do
      it { expect { recv_nonblock }.to raise_error(Chan::WaitReadable) }
    end

    context "when a lock is held by another process" do
      let(:lock) { ch.instance_variable_get(:@lock).obtain }
      let!(:child_pid) { fork { lock.then { sleep 5 } } }

      before { ch.send([1]).then { sleep(delay) } }
      after { Process.kill("SIGKILL", child_pid) }

      it { expect { recv_nonblock }.to raise_error(Chan::WaitLockable) }
    end
  end

  describe "#bytes_written" do
    subject { ch.bytes_written }
    let(:payload) { %w[xchan] }
    let(:payload_size) { ch.serializer.dump(payload).bytesize }

    context "when one write takes place" do
      before { Process.wait fork { ch.send(payload) } }
      it { is_expected.to eq(payload_size) }
    end

    context "when two writes take place" do
      before { Process.wait fork { 2.times { ch.send(payload) } } }
      it { is_expected.to eq(payload_size * 2) }
    end
  end

  describe "#bytes_read" do
    subject { ch.bytes_read }
    let(:payload) { %w[xchan] }
    let(:payload_size) { ch.serializer.dump(payload).bytesize }

    context "when one read takes place do" do
      before do
        ch.send(payload)
        Process.wait fork { ch.recv }
      end
      it { is_expected.to eq(payload_size) }
    end

    context "when two reads take place" do
      before do
        2.times { ch.send payload }
        Process.wait fork { 2.times { ch.recv } }
      end
      it { is_expected.to eq(payload_size * 2) }
    end
  end

  describe "#empty?" do
    subject { ch }

    context "when a write hasn't taken place" do
      it { is_expected.to be_empty }
    end

    context "when a write takes place" do
      before { ch.send(%w[foo]) }

      it { is_expected.to_not be_empty }

      context "when a read takes place" do
        before { ch.read }
        it { is_expected.to be_empty }
      end

      context "when the channel is closed" do
        before { ch.close }
        it { is_expected.to be_empty }
      end
    end
  end

  describe "#to_a" do
    context "when used by the splat operator" do
      subject { lambda { |a, b, c| [a, b, c] }.call(*ch) }
      before { 1.upto(3) { ch.send([_1]) } }
      it { is_expected.to eq([[1], [2], [3]]) }
    end

    context "when used to read the most recent write" do
      subject { ch.to_a.last }
      before { 1.upto(5) { ch.send [_1] } }
      it { is_expected.to eq([5]) }
    end

    context "when used to consume the contents of the channel" do
      subject { ch.to_a }
      before { 1.upto(3) { ch.send [_1] } }
      it { is_expected.to eq([[1], [2], [3]]) }
    end

    context "when the channel is empty" do
      subject { ch.to_a }
      it { is_expected.to eq([]) }
    end
  end

  describe "#size" do
    subject { ch.size }

    context "when one write takes place" do
      before { ch.send([1]) }
      it { is_expected.to eq(1) }

      context "when a read takes place" do
        before { ch.recv }
        it { is_expected.to be_zero }
      end
    end

    context "when two writes take place" do
      before { 2.times { ch.send([1]) } }
      it { is_expected.to eq(2) }

      context "when a read takes place" do
        before { ch.recv }
        it { is_expected.to eq(1) }
      end
    end
  end
end

RSpec.describe Chan::UNIXSocket do
  include_examples "xchan", :marshal
  include_examples "xchan", :yaml
  include_examples "xchan", :json
end
