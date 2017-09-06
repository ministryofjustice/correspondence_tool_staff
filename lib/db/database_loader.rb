class DatabaseLoader

  def initialize(env, file)
    @env = env
    @file = file
    raise "Only 'local' evironment is currently supported" unless @env == 'local'
  end

  def run
    unzipped_file_name = unzip_file
    updated_file_name = add_role(unzipped_file_name)
    drop_and_recreate_database
    load_database(updated_file_name)
  end

  private

  def unzip_file
    puts "Unzipping file #{@file}"
    system "gunzip #{@file}"
    @file.sub(/\.gz$/, '')
  end

  def add_role(filename)
    system "sed -e $'1i\\\nCREATE ROLE correspondence_staff;\n' -i .bak #{filename}"
    puts "File #{filename} updated to add CREATE ROLE line - original saved in #{filename}.bak"
    filename
  end

  def drop_and_recreate_database
    ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1'
    Rake::Task['db:drop'].invoke
    puts "Database dropped"
    Rake::Task['db:create'].invoke
    puts "Database created"
  end

  def load_database(updated_file_name)
    database_url = 'postgres://localhost/correspondence_platform_development'
    command = "psql #{database_url } < #{updated_file_name}"
    puts "Executing: #{command}"
    result = system command
    if result == true
      puts 'Database successfully loaded'
    else
      puts 'Error loading database'
    end
  end
end
