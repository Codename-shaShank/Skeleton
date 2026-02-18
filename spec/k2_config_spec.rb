require_relative 'spec_helper'

describe K2Config do
  describe '.dependency_upgraded_next?' do
    it 'returns false when environment variable is not set' do
      ENV.delete('K2_DEPENDENCY_UPGRADED_NEXT')
      expect(K2Config.dependency_upgraded_next?).to eq(false)
    end
    
    it 'returns false when environment variable is set to false' do
      ENV['K2_DEPENDENCY_UPGRADED_NEXT'] = 'false'
      expect(K2Config.dependency_upgraded_next?).to eq(false)
    end
    
    it 'returns true when environment variable is set to true' do
      ENV['K2_DEPENDENCY_UPGRADED_NEXT'] = 'true'
      expect(K2Config.dependency_upgraded_next?).to eq(true)
    end
    
    after(:each) do
      # Clean up environment variable after each test
      ENV.delete('K2_DEPENDENCY_UPGRADED_NEXT')
    end
  end
end
