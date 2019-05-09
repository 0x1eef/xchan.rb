require_relative 'setup'
RSpec.describe ZChannel do 
  let(:ch) do 
    ZChannel.unix Object.const_get(ENV["SERIALIZER"] || "Marshal")
  end 

  describe '#recv' do
    it 'receives a string with a null byte' do
      ch.send ["hello\x00"]
      expect(ch.recv).to eq(["hello\x00"]) 
      ch.close
    end

    it 'blocks until content is available' do 
      expect {
        Timeout.timeout(1) { ch.recv }
      }.to raise_error(Timeout::Error)
    end
  end 
  
  describe '#recv!' do
    it 'raises Timeout::Error after waiting 1 second' do 
      expect {
        ch.recv!(1)
      }.to raise_error(ZChannel::TimeoutError)
    end
  end

  describe '#last_msg' do 
    it 'returns the last message written to a channel' do 
      ch.send [42]
      ch.send [43]
      expect(ch.last_msg).to eq([43])
    end
  end
end
