require 'colorize'
require 'shell-spinner'
require 'ruby-progressbar'

class DatabaseDumper

  HOST_NAMES = {
    'prod' => 'prod.cts',
    'demo' => 'demo.cts'
  }.freeze

  def initialize(env, host)
    puts "Create SQL dump of #{env} environemnt on host #{host} - run rake db:dump:help for assistance".yellow
    @ssh_user = ENV['CTS_SSH_USER']
    exit_with_error('No CTS_SSH_USER environment variable found') if @ssh_user.blank?
    @env = env
    @host = host.blank? ? HOST_NAMES[@env] : host
  end

  def run
    check_is_necessary
    begin
      client_filename = dump_local_database
      compressed_file = compress_file(client_filename)
      copy_to_container_host(compressed_file)
      download_compressed_file(compressed_file)
      remove_files_on_host_and_container(compressed_file)
      puts "Dumpfile #{ENV['HOME']}/#{compressed_file} created".yellow
    rescue => err
      puts err.message
      puts err.backtrace
      exit_with_error(err.message)
    end
  end

  private

  def check_is_necessary
    puts 'Are you sure you need to do this data dump?'
    puts 'Could you solve the issue with any other option such as...'
    print "Please confirm that you wish to continue "
    x = STDIN.gets.chomp
    exit unless (x == 'y' || x == 'Y')
  end

  def dump_local_database
    filename = "#{Time.now.strftime('%Y%m%d-%H%M%S')}_#{@env}_dump.sql"
    ssh_command = "ssh #{@ssh_user}@#{@host} sudo docker exec correspondence-staff rake db:dump:local[#{filename}]"
    puts "Executing: #{ssh_command}"
    result = system ssh_command
    raise 'Unable to execute SSH command' unless result == true
    filename
  end

  def compress_file(filename)
    ssh_command = "ssh #{@ssh_user}@#{@host} sudo docker exec correspondence-staff gzip  -3 -f #{filename}"
    puts "Executing: #{ssh_command}"
    result = system ssh_command
    raise 'Unable to execute SSH command' unless result == true
    filename + '.gz'
  end

  def copy_to_container_host(filename)
    ssh_command = "ssh #{@ssh_user}@#{@host} sudo docker cp correspondence-staff:/usr/src/app/#{filename} ."
    puts "Executing: #{ssh_command}"
    result = system ssh_command
    raise 'Unable to execute SSH command' unless result == true
  end

  def download_compressed_file(compressed_file)
    puts 'Downloading dump file %s from host %s' % [compressed_file, @host]
    scp_command = "scp #{@ssh_user}@#{@host}:#{compressed_file} #{ENV['HOME']}/"
    puts "Executing: #{scp_command}"
    result = system scp_command
    raise 'Unable to execute SSH command' unless result == true
  end

  def remove_files_on_host_and_container(compressed_file)
    ssh_command = "ssh #{@ssh_user}@#{@host} sudo docker exec correspondence-staff rm /usr/src/app/#{compressed_file}"
    puts "Executing: #{ssh_command}"
    system ssh_command

    ssh_command = "ssh #{@ssh_user}@#{@host} rm #{compressed_file}"
    puts "Executing: #{ssh_command}"
    result = system ssh_command
    raise 'Unable to execute SSH command' unless result == true
  end

  def exit_with_error(message)
    puts message.red
    Rake::Task['db:dump:help'].invoke
    exit 2
  end



end
