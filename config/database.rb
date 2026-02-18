# Log queries to STDOUT in development
if Sinatra::Application.development?
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end

# Automatically load every file in APP_ROOT/app/models/*.rb, e.g.,
#   autoload "Person", 'app/models/person.rb'
#
# We have to do this in case we have models that inherit from each other.
# If model Student inherits from model Person and app/models/student.rb is
# required first, it will throw an error saying "Person" is undefined.
#
# With this lazy-loading technique, Ruby will try to load app/models/person.rb
# the first time it sees "Person" and will only throw an exception if
# that file doesn't define the Person class.
#
# See http://www.rubyinside.com/ruby-techniques-revealed-autoload-1652.html
Dir[APP_ROOT.join('app', 'models', '*.rb')].each do |model_file|
  filename = File.basename(model_file).gsub('.rb', '')
  autoload ActiveSupport::Inflector.camelize(filename), model_file
end

# Heroku controls what database we connect to by setting the DATABASE_URL environment variable
# We need to respect that if we want our Sinatra apps to run on Heroku without modification
db = URI.parse(ENV['DATABASE_URL'] || "postgres://localhost/#{APP_NAME}_#{Sinatra::Application.environment}")

DB_NAME = db.path[1..-1]

# Note:
#   Sinatra::Application.environment is set to the value of ENV['RACK_ENV']
#   if ENV['RACK_ENV'] is set.  If ENV['RACK_ENV'] is not set, it defaults
#   to :development

# Connection configuration
# Note: pg gem 0.17.1 -> 0.18.4 upgrade doesn't require code changes here
# because we use ActiveRecord which abstracts the pg gem API.
# If we needed pg-version-specific behavior, we would use:
#
# connection_options = {
#   :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
#   :host     => db.host,
#   :port     => db.port,
#   :username => db.user,
#   :password => db.password,
#   :database => DB_NAME,
#   :encoding => 'utf8'
# }
#
# if K2Config.dependency_upgraded_next?
#   # pg 0.18.4 specific configuration (if needed)
#   # Example: connection_options[:some_new_option] = value
#   # Changelog: https://github.com/ged/ruby-pg/blob/master/CHANGELOG.md#v0184-2015-11-13
# end
#
# ActiveRecord::Base.establish_connection(connection_options)

ActiveRecord::Base.establish_connection(
  :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
  :host     => db.host,
  :port     => db.port,
  :username => db.user,
  :password => db.password,
  :database => DB_NAME,
  :encoding => 'utf8'
)