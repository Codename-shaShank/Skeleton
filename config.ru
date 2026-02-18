# Require config/environment.rb
require File.expand_path('config/environment', __dir__)

set :app_file, __FILE__

run Sinatra::Application
