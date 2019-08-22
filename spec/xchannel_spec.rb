require_relative 'setup'
RSpec.describe XChannel do 
  let(:ch) do 
    XChannel.from_unix_socket Object.const_get(ENV["SERIALIZER"] || "Marshal")
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
      ch.close
    end
  end 
  
  describe '#recv!' do
    it 'raises XChannel::TimeoutError after waiting 1 second  for content to become available' do 
      expect {
        ch.recv!(1)
      }.to raise_error(XChannel::TimeoutError)
      ch.close
    end
  end

  describe '#last_msg' do 
    it 'returns the last message written to a channel' do 
      ch.send [42]
      ch.send [43]
      expect(ch.last_msg).to eq([43])
      ch.close
    end
  end
end
