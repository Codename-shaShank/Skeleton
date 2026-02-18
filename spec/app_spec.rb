require 'spec_helper'

describe 'Skeleton Application' do
  describe 'GET /' do
    it 'returns a successful response' do
      get '/'
      expect(last_response).to be_ok
    end

    it 'displays the home page' do
      get '/'
      expect(last_response.body).to include('All Notes')
    end

    it 'lists all notes' do
      Note.create(name: 'First Note')
      Note.create(name: 'Second Note')

      get '/'
      expect(last_response.body).to include('First Note')
      expect(last_response.body).to include('Second Note')
    end
  end
end
