
namespace :db do
  namespace :dump  do

    desc 'Help text for rake db:dump:* tasks'
    task :help do
      puts 'rake db:dump:<environment> will produce an SQL dump of the database from the '.yellow
      puts ' specified environment (prod, demo, staging).'.yellow
      puts ' '
      puts 'SSH username:'.yellow
      puts 'The ssh username used to connect to the remote server must be specified in the'.yellow
      puts 'CTS_SSH_USER environment variable.'.yellow
      puts ' '
      puts 'Hostname:'.yellow
      puts 'The hostname or IP address can be specified as a parameter, for example'.yellow
      puts ' '
      puts '   rake db:dump:demo[123.202.5.66]'.yellow
      puts ' '
      puts 'or the following hostnames will be assumed if none specified:'.yellow
      puts '  prod      prod.cts'.yellow
      puts '  demo      demo.cts'.yellow
      puts '  staging   stage.cts'.yellow
    end


    desc 'makes a sql dump of the production database and copies to the local machine'
    task :prod, [:host] do |_task, args|
      require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')
      DatabaseDumper.new('prod', args[:host], 'anon').run
    end

    desc 'makes an sql dump of the database on the demo environement to the local machine'
    task :demo, [:host] do |_task, args|
      require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')
      DatabaseDumper.new('demo', args[:host], 'clear').run
    end


    desc 'makes an sql dump of the database on the staging environment to the local machine'
    task :staging, [:host] do |_task, args|
      require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')
      DatabaseDumper.new('demo', args[:host], 'clear').run
    end

    desc 'makes an anonymised dump of the local database'
    task :local, [:filename, :anonymized] => :environment do |_task, args|require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')
      require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_anonymizer')
      filename = args[:filename]
      raise "Must specify a filename" if filename.blank?
      raise "Second argument must be 'anon' or 'clear', is: #{args[:anonymized]}" unless args[:anonymized].in?(%w( anon clear ))
      db_connection_url = ENV['DATABASE_URL'] || 'postgres://localhost/correspondence_platform_development'
      if args[:anonymized] == 'anon'
        ShellSpinner 'exporting unanonymised database data' do
          system "pg_dump #{db_connection_url} #{DatabaseDumper.excluded_anonymised_tables} --insert -f #{filename}"
        end
        ShellSpinner 'adding anonymised tables' do
          DatabaseAnonymizer.new(filename).run
        end
      else
        ShellSpinner 'exporting unanonymised database data' do
          system "pg_dump #{db_connection_url} --insert -f #{filename}"
        end
      end

    end
  end

  namespace :load do
    desc 'Loads an SQL dump of the database created by db:dump:<env> rake task to the local database'
    task :local, [:file] => :environment do |_task, args|
      require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_loader')
      DatabaseLoader.new('local', args[:file]).run
    end

  end

end
