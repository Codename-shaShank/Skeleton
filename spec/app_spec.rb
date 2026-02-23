require 'spec_helper'

describe 'Skeleton Application' do
  describe 'GET /' do
    it 'returns a successful response' do
      get '/'
      expect(last_response).to be_ok
    end

    it 'displays the home page' do
      get '/'
      expect(last_response.body).to include('meow meow')
    end
  end
end
