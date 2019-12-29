require_relative 'setup'
RSpec.describe XChan do
  let(:ch) do
    xchan Object.const_get(ENV["SERIALIZER"] || "Marshal")
  end

  after do
    ch.close unless ch.closed?
  end

  describe '#recv' do
    it 'receives a string with a null byte' do
      ch.send ["hello\x00"]
      expect(ch.recv).to eq(["hello\x00"])
    end

    it 'blocks until message is available' do
      expect {
        Timeout.timeout(1) { ch.recv }
      }.to raise_error(Timeout::Error)
    end
  end

  describe '#recv!' do
    it 'raises XChan::TimeoutError after waiting for message to become available' do
      expect {
        ch.recv!(1)
      }.to raise_error(XChan::TimeoutError)
    end
  end

  describe '#readable?' do
    it 'returns false when there are no messages waiting to be read' do
      expect(ch).to_not be_readable
    end

    it 'returns false when the channel is closed' do
      ch.send [1]
      ch.close
      expect(ch).to_not be_readable
    end

    it 'returns true when there is a message waiting to be read' do
      ch.send [1]
      expect(ch).to be_readable
    end
  end

  describe '#last_msg' do
    it 'returns the last message written to a channel' do
      ch.send [1]
      ch.send [2]
      expect(ch.last_msg).to eq([2])
    end
  end
end
