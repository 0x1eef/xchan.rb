require_relative 'setup'
RSpec.describe XChan do
  let(:ch) do
    xchan Object.const_get(ENV["SERIALIZER"] || "Marshal")
  end

  after do
    ch.close unless ch.closed?
  end

  describe '#send' do
    it 'raises NilError when false or nil is written to a channel' do
      expect { ch.send(nil) }.to raise_error(XChan::NilError)
      expect { ch.send(false) }.to raise_error(XChan::NilError)
    end

    it 'returns an integer when successful' do
      expect(ch.send [1]).to be_instance_of(Integer)
    end
  end

  describe '#recv' do
    it 'returns a string with a null byte' do
      ch.send ["hello\x00"]
      expect(ch.recv).to eq(["hello\x00"])
    end

    it 'performs a blocking read' do
      expect { Timeout.timeout(1) { ch.recv } }.to raise_error(Timeout::Error)
    end
  end

  describe '#timed_recv' do
    it 'returns nil when a read times out' do
      expect(ch.timed_recv(0.1)).to eq(nil)
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
      [1,2,3,4,5].each {|number| ch.send [number]}
      expect(ch.last_msg).to eq([5])
    end
  end
end
