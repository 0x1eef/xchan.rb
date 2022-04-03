# frozen_string_literal: true

require_relative "setup"

RSpec.shared_examples "xchan" do |serializer|
  let!(:ch) do
    xchan(serializer)
  end

  after do
    ch.close unless ch.closed?
  end

  describe "#send" do
    subject(:payload) { %w[xchan] }
    let(:payload_size) { ch.serializer.dump(payload).bytesize }

    context "when returning the number of bytes written" do
      subject { ch.send(payload) }
      it { is_expected.to eq(payload_size) }
    end

    context "when queueing messages from a child process" do
      subject { 3.times.map { ch.recv } }
      before { Process.wait fork { 1.upto(3) { ch.send([_1]) } } }
      it { is_expected.to eq([[1], [2], [3]]) }
    end
  end

  describe "#recv" do
    subject { ch.recv }

    context "when given a write with a null byte" do
      before { ch.send(["nullbyte\x00"]) }
      it { is_expected.to eq(["nullbyte\x00"]) }
    end

    context "when a read should block" do
      subject(:recv) { timeout(0.1) { ch.recv } }
      include Timeout
      it { expect { recv }.to raise_error(Timeout::Error) }
    end
  end

  describe "#recv_nonblock" do
    subject(:recv_nonblock) { ch.recv_nonblock }

    context "when a channel is empty" do
      it { expect { recv_nonblock }.to raise_error(Chan::WaitReadable) }
    end

    context "when a lock is held by another process" do
      let(:lock) { ch.instance_variable_get(:@lock).obtain }
      let!(:child_pid) { fork { lock.then { sleep 5 } } }

      before { ch.send([1]).then { sleep 0.3 } }
      after { Process.kill("SIGKILL", child_pid) }

      it { expect { recv_nonblock }.to raise_error(Chan::WaitLockable) }
    end
  end

  describe "#readable?" do
    subject { ch }

    context "when a write hasn't taken place" do
      it { is_expected.to_not be_readable }
    end

    context "when a write takes place" do
      before { ch.send([1]) }
      it { is_expected.to be_readable }

      context "when the channel is closed" do
        before { ch.close }
        it { is_expected.to_not be_readable }
      end

      context "when the channel is locked" do
        before do
          ch.instance_variable_set(:@lock, lock)
        end

        let(:lock) do
          double({
            "locked?" => true,
            :synchronize => nil,
            :file => double(close: nil)
          })
        end

        it { is_expected.to_not be_readable }
      end
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
