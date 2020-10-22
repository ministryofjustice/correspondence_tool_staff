
# This taks is to provide the following 3 functions
# - dumper dump clear DB as compressed-sql files from remote env to local  
#   the assumption for use this command to do this is to run it on your local env and you need to have the 
#   the permission to access those environment and it is via kubectl exec command
#   This part is based on the existing codes with  changes from ssh to kubectl exec command
# - anonymizer: dump anonymised db as compressed-sql files against local db from remote env or local db with options to upload 
#   to s3 buckets 
#   This part is not take environment as the input, if you want to run it on remote pod but from local env please use other 
#   facilities to run it e.g. kubectl exec
# 
#   The process of db anoymizer is below
#     - dump the basic data out of target database 
#     - dump the data out of db per table base
#       - check whether this table is within the tables which require anonymised
#       - if does, then call anon
#       - compress the outcome 
#       - if the env is remote, then upload into s3 bucket.
# - bucket_downloader
#   Download the  
# - restorer 
#    restore the sql files into target db (non-prod env) 
#    -- drop the schema at target table
#    -- import the data per table bases into the target the db
#    -- run migratoins
#    -- run udpate for search index
#    -- restart the instances
#    -- not sure whether we need to reindex at database level

#   Safegurd checking 
#   - manul checking list
#   - auto-checking approach 
#     e.g. - any database schema changes and the data model's attributes changes
#      keep the latest coppy of schema and the data model structure 
#      scan current db schema and data models structure
#      calculate the hash value/ md5_sum values based on the content of current and latest copy
#      if different, then die out 
#      The only way which can fix this problem is to run separated task to update the copy in the cloud
require 'open3'
# require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')


namespace :db do
  namespace :dump  do

    desc 'Help text for rake db:dump:* tasks'
    task :help do
      puts 'rake db:dump:<environment> will produce an SQL dump of the database from the '.yellow
      puts 'rake db:dump:anonymized will process anonymisation again the database the current env/pod connects with '.yellow
      puts 'rake db:dump:download will download'.yellow
      puts 'rake db:dump:restore will process restore '.yellow
      # puts 'rake db:dump:<environment> will produce an SQL dump of the database from the '.yellow
      # puts ' specified environment (prod, demo, staging).'.yellow
      # puts ' '
      # puts 'SSH username:'.yellow
      # puts 'The ssh username used to connect to the remote server must be specified in the'.yellow
      # puts 'CTS_SSH_USER environment variable.'.yellow
      # puts ' '
      # puts 'Hostname:'.yellow
      # puts 'The hostname or IP address can be specified as a parameter, for example'.yellow
      # puts ' '
      # puts '   rake db:dump:demo[123.202.5.66]'.yellow
      # puts ' '
      # puts 'or the following hostnames will be assumed if none specified:'.yellow
      # puts '  prod      prod.cts'.yellow
      # puts '  demo      demo.cts'.yellow
      # puts '  staging   stage.cts'.yellow
    end


    desc 'makes a sql dump of the production database and copies to the local machine'
    task :prod, [:host] do |_task, args|
      # require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')
      safeguard
      chosen_first_pod = get_first_pod("production")
      raise "Cannot find the available pod from this env" unless chosen_first_pod.present?

      prefix_command = "kubectl exec -it #{chosen_first_pod} -n track-a-query-production -c webapp "
      dump_files = DatabaseDumper.new(true).run
      dump_files.each do | compressed_file |
        download_compressed_file(compressed_file, "track-a-query-production", chosen_first_pod)
        remove_files_on_container(compressed_file, prefix_command: prefix_command)
      end
    end

    # desc 'makes an sql dump of the database on the demo environement to the local machine'
    # task :demo, [:host] do |_task, args|
    #   # require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')
    #   DatabaseDumper.new('demo', args[:host], 'clear').run
    # end

    # desc 'makes an sql dump of the database on the staging environment to the local machine'
    # task :staging, [:host] do |_task, args|
    #   # require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')
    #   DatabaseDumper.new('demo', args[:host], 'clear').run
    # end

    desc 'makes an anonymised dump of the local database'
    task :local, [:anonymized] => :environment do |_task, args|
      require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_dumper')
      raise "Second argument must be 'anon' or 'clear', is: #{args[:anonymized]}" unless args[:anonymized].in?(%w( anon clear ))
      ShellSpinner 'exporting unanonymised database data' do
        DatabaseDumper.new(args[:anonymized] == 'anon').run
      end
    end

    private

    def safeguard
      puts 'Are you sure you need to do this data dump?'
      puts ''
      question_user('is the issue covered with existing feature tests? ')
      question_user('can you track problem through Kibana? ')
      question_user('can you recreate the problem locally? ')
      question_user('can you recreate the problem on staging with an anonymised dump? ')
      confirm_data_dump
      verify_password
    end

    def question_user(query)
      print query
      input = STDIN.gets.chomp
      unless(input.downcase.start_with?('n')) || input.nil?
        puts 'exiting'
        exit
      end
    end

    def confirm_data_dump
      print "If you are still certain that you need to make a dump of the database please confirm y/n "
      input = STDIN.gets.chomp
      exit unless(input.downcase.start_with?('y')) || input.nil?
    end

    def get_first_pod(working_env)
      pod_name = nil
      output = Open3.popen3("kubectl get pods -n track-a-query-development") { |stdin, stdout, stderr, wait_thr| stdout.read }
      if output.present?
        output_lines = output.split('\n')
        if output_lines.count >= 2
          pod_name = output_lines[1].split(' ')[0].delete(' ')
        end 
      end
      pod_name
    end

  end

  namespace :restore do
    desc 'Loads an SQL dump of the database created by db:dump:<env> rake task to the local database'
    task :local, [:file] => :environment do |_task, args|
      require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_loader')
      DatabaseLoader.new('local', args[:file]).run
    end

  end

end
