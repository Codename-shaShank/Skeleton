require_relative 'spec_helper'

describe 'Skeleton Application' do
  it 'loads the home page' do
    get '/'
    expect(last_response).to be_ok
  end
  
  it 'has the correct title' do
    get '/'
    expect(last_response.body).to include('All Notes')
  end
end
