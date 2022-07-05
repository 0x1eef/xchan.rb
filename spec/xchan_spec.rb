require_relative "setup"
RSpec.describe XChan do
  let(:ch) do
    xchan Object.const_get(ENV["SERIALIZER"] || "Marshal")
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

    it "consistently returns the number of written bytes by the last write" do
      expect(ch.send(payload)).to eq(payload_size)
      expect(ch.send(payload)).to eq(payload_size)
    end
  end

  describe "#recv" do
    it "returns a string with a null byte" do
      ch.send ["hello\x00"]
      expect(ch.recv).to eq(["hello\x00"])
    end

    it "performs a blocking read" do
      expect { Timeout.timeout(1) { ch.recv } }.to raise_error(Timeout::Error)
    end
  end

  describe "#timed_recv" do
    it "returns nil when a read times out" do
      expect(ch.timed_recv(0.1)).to eq(nil)
    end
  end

  describe "#readable?" do
    it "returns false when there are no messages waiting to be read" do
      expect(ch).to_not be_readable
    end

    it "returns false when the channel is closed" do
      ch.send [1]
      ch.close
      expect(ch).to_not be_readable
    end

    it "returns true when there is a message waiting to be read" do
      ch.send [1]
      expect(ch).to be_readable
    end
  end

  describe "#bytes_written" do
    let(:payload) { %w[0x1eef] }
    let(:payload_size) { ch.serializer.dump(payload).bytesize }

    it "records the bytes written by one message" do
      ch.send payload
      expect(ch.bytes_written).to eq(payload_size)
    end

    it "records the bytes written by two messages" do
      2.times { ch.send payload }
      expect(ch.bytes_written).to eq(payload_size * 2)
    end
  end

  describe "#bytes_read" do
    let(:payload) { %w[0x1eef] }
    let(:payload_size) { ch.serializer.dump(payload).bytesize }

    it "records the bytes read from one message" do
      ch.send payload
      ch.recv
      expect(ch.bytes_read).to eq(payload_size)
    end

    it "records the bytes read from two messages" do
      2.times { ch.send payload }
      2.times { ch.recv }
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
end
