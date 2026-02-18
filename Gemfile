source 'https://rubygems.org'
ruby '3.2.3'

# PostgreSQL driver
gem 'pg', '~> 1.0'

# Sinatra driver
gem 'sinatra'
gem 'sinatra-contrib'

# Use Thin for our web server
gem 'thin'

gem 'activerecord', '~> 7.0'
gem 'activesupport', '~> 7.0'

gem 'rake'

gem 'shotgun'

group :test do
  gem 'rack-test'
  gem 'shoulda-matchers'
end

group :test, :development do
  gem 'factory_girl'
  gem 'faker'
  gem 'rspec'
  gem 'rubocop', require: false
end
