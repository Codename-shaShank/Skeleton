ENV['RACK_ENV'] = 'test'

require File.expand_path('../../config/environment', __FILE__)
require 'rspec'
require 'rack/test'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  
  # Use color in output
  config.color = true
  
  # Use the specified formatter
  config.formatter = :documentation
  
  # Clean up database between tests
  config.before(:suite) do
    # Set up test database if needed
  end
  
  config.after(:each) do
    # Clean up after each test if needed
  end
end

def app
  Sinatra::Application
end
