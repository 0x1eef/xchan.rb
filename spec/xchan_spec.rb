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
    let(:payload) { %w[0x1eef] }
    let(:payload_size) { ch.serializer.dump(payload).bytesize }

    it "returns the number of written bytes" do
      expect(ch.send(payload)).to eq(payload_size)
    end

    context "when queueing messages from a child process" do
      subject { 3.times.map { ch.recv } }
      before { Process.wait fork { 1.upto(3) { ch.send([_1]) } } }
      it { is_expected.to eq([[1], [2], [3]]) }
    end
  end

  describe "#recv" do
    it "returns a string with a null byte" do
      ch.send ["hello\x00"]
      expect(ch.recv).to eq(["hello\x00"])
    end

    it "performs a blocking read" do
      expect { Timeout.timeout(0.1) { ch.recv } }.to raise_error(Timeout::Error)
    end
  end

  describe "#timed_recv" do
    it "returns nil when a read times out" do
      expect(ch.timed_recv(timeout: 0.1)).to eq(nil)
    end
  end

  describe "#readable?" do
    subject { ch.readable? }

    it "returns false when the channel is empty" do
      expect(ch).to_not be_readable
    end

    it "returns false when the channel is closed" do
      ch.send [1]
      ch.close
      expect(ch).to_not be_readable
    end

    it "returns true when an object is waiting to be read" do
      ch.send [1]
      expect(ch).to be_readable
    end

    context "when the channel is locked" do
      let(:lock) do
        instance_double(
          'Chan::Lock',
          {'locked?' => true, release: nil, obtain: nil, close: nil}
        )
      end

      before do
        ch.instance_variable_set(:@lock, lock)
        ch.send([1])
      end

      it { is_expected.to eq(false) }
    end
  end

  describe "#bytes_written" do
    let(:payload) { %w[0x1eef] }
    let(:payload_size) { ch.serializer.dump(payload).bytesize }

    it "records the bytes written by one message" do
      Process.wait fork { ch.send(payload) }
      expect(ch.bytes_written).to eq(payload_size)
    end

    it "records the bytes written by two messages" do
      Process.wait fork { 2.times { ch.send(payload) } }
      expect(ch.bytes_written).to eq(payload_size * 2)
    end
  end

  describe "#bytes_read" do
    let(:payload) { %w[0x1eef] }
    let(:payload_size) { ch.serializer.dump(payload).bytesize }

    it "records the bytes read from one message" do
      ch.send(payload)
      Process.wait fork { ch.recv }
      expect(ch.bytes_read).to eq(payload_size)
    end

    it "records the bytes read from two messages" do
      2.times { ch.send payload }
      Process.wait fork { 2.times { ch.recv } }
      expect(ch.bytes_read).to eq(payload_size * 2)
    end
  end

  describe "#empty?" do
    subject { ch }

    context "when the channel is considered empty" do
      context "when a write hasn't taken place" do
        it { is_expected.to be_empty }
      end

      context "when a write has taken place" do
        before { ch.send(%w[foo]) }
        context "when the channel is read from" do
          before { ch.read }
          it { is_expected.to be_empty }
        end

        context "when the channel is closed" do
          before { ch.close }
          it { is_expected.to be_empty }
        end
      end
    end

    context "when the channel is not considered empty" do
      context "when a write has taken place" do
        before { ch.send(%w[foo]) }
        it { is_expected.to_not be_empty }
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

    context "when one object is written to the channel" do
      before { ch.send([1]) }
      it { is_expected.to eq(1) }

      context "when a read is performed" do
        before { ch.recv }
        it { is_expected.to be_zero }
      end
    end

    context "when two objects are written to the channel" do
      before { 2.times { ch.send([1]) } }
      it { is_expected.to eq(2) }

      context "when a read is performed" do
        before { ch.recv }
        it { is_expected.to eq(1) }
      end
    end
  end
end

RSpec.describe "xchan" do
  include_examples "xchan", :marshal
  include_examples "xchan", :yaml
  include_examples "xchan", :json
end
