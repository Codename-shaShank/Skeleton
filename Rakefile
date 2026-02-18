require 'rake'
require 'rspec/core/rake_task'

require File.expand_path('config/environment', __dir__)

# Include all of ActiveSupport's core class extensions, e.g., String#camelize
require 'active_support/core_ext'

# Load ActiveRecord rake tasks
require 'active_record'

namespace :generate do
  desc 'Create an empty model in app/models, e.g., rake generate:model NAME=User'
  task :model do
    raise 'Must specificy model name, e.g., rake generate:model NAME=User' unless ENV.key?('NAME')

    model_name     = ENV['NAME'].camelize
    model_filename = "#{ENV['NAME'].underscore}.rb"
    model_path = APP_ROOT.join('app', 'models', model_filename)

    raise "ERROR: Model file '#{model_path}' already exists" if File.exist?(model_path)

    puts "Creating #{model_path}"
    File.open(model_path, 'w+') do |f|
      f.write(<<-EOF.strip_heredoc)
        class #{model_name} < ActiveRecord::Base
          # Remember to create a migration!
        end
      EOF
    end
  end

  desc 'Create an empty migration in db/migrate, e.g., rake generate:migration NAME=create_tasks'
  task :migration do
    raise 'Must specificy migration name, e.g., rake generate:migration NAME=create_tasks' unless ENV.key?('NAME')

    name     = ENV['NAME'].camelize
    filename = format('%s_%s.rb', Time.now.strftime('%Y%m%d%H%M%S'), ENV['NAME'].underscore)
    path     = APP_ROOT.join('db', 'migrate', filename)

    raise "ERROR: File '#{path}' already exists" if File.exist?(path)

    puts "Creating #{path}"
    File.open(path, 'w+') do |f|
      f.write(<<-EOF.strip_heredoc)
        class #{name} < ActiveRecord::Migration
          def change
          end
        end
      EOF
    end
  end

  desc 'Create an empty model spec in spec, e.g., rake generate:spec NAME=user'
  task :spec do
    raise 'Must specificy migration name, e.g., rake generate:spec NAME=user' unless ENV.key?('NAME')

    name     = ENV['NAME'].camelize
    filename = '%s_spec.rb' % ENV['NAME'].underscore
    path     = APP_ROOT.join('spec', filename)

    raise "ERROR: File '#{path}' already exists" if File.exist?(path)

    puts "Creating #{path}"
    File.open(path, 'w+') do |f|
      f.write(<<-EOF.strip_heredoc)
        require 'spec_helper'

        describe #{name} do
          pending "add some examples to (or delete) #{__FILE__}"
        end
      EOF
    end
  end
end

namespace :db do
  desc 'Drop, create, and migrate the database'
  task reset: %i[drop create migrate]

  desc "Create the databases at #{DB_NAME}"
  task :create do
    puts "Creating development and test databases if they don't exist..."
    system("createdb #{APP_NAME}_development && createdb #{APP_NAME}_test")
  end

  desc "Drop the database at #{DB_NAME}"
  task :drop do
    puts 'Dropping development and test databases...'
    system("dropdb #{APP_NAME}_development && dropdb #{APP_NAME}_test")
  end

  desc 'Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=blog).'
  task :migrate do
    ActiveRecord::Base.logger = Logger.new($stdout) if ENV['VERBOSE'] == 'true'
    version = ENV['VERSION']&.to_i
    ActiveRecord::Tasks::DatabaseTasks.migrate(version)
  end

  desc 'Populate the database with dummy data by running db/seeds.rb'
  task :seed do
    require APP_ROOT.join('db', 'seeds.rb')
  end

  desc 'Returns the current schema version number'
  task :version do
    puts "Current version: #{ActiveRecord::MigrationContext.new('db/migrate', ActiveRecord::SchemaMigration).current_version}"
  end

  desc 'rollback your migration--use STEPS=number to step back multiple times'
  task :rollback do
    steps = (ENV['STEPS'] || 1).to_i
    ActiveRecord::MigrationContext.new('db/migrate', ActiveRecord::SchemaMigration).rollback(steps)
    Rake::Task['db:version']&.invoke
  end

  namespace :test do
    desc 'Migrate test database'
    task :prepare do
      system 'rake db:migrate RACK_ENV=test'
    end
  end
end

desc 'Start IRB with application environment loaded'
task 'console' do
  exec 'irb -r./config/environment'
end

desc 'Run the specs'
RSpec::Core::RakeTask.new(:spec)

task default: :spec
