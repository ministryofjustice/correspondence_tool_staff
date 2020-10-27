#  This class is to provide easy functin to get the data out of environent and anonymize them
#  initial plan is to not provide clear option
#

class DatabaseDumper

  attr_reader :outcome_files

  TABLES_TO_BE_EXCLUDED = ["reports", "search_queries", "sessions", "versions"]

  def initialize(anonymize, tag, where_to_stored)
    @anonymize = anonymize
    @anonymizer = nil
    @db_connection_url = ENV['DATABASE_URL'] || 'postgres://localhost/correspondence_platform_development'
    @s3_bucket = S3BucketHelper::S3Bucket.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"])
    @outcome_files = []
    @tag = tag
    @where_to_stored = where_to_stored
  end

  def run
    # dump_schema_screenshot
    dump_local_database
    @outcome_files
  end

  private

  def dump_local_database
    require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_anonymizer')
    require File.join(Rails.root, 'lib', 'tasks', 'rake_task_helpers', 'dumper_utils')

    created_at = Time.now.strftime('%Y%m%d-%H%M%S')
    dirname = "./dumps_#{@tag}"
    FileUtils.mkpath(dirname)
    base_file_name = "#{dirname}/#{@tag}_#{created_at}"
    @anonymizer = DatabaseAnonymizer.new()
    
    @outcome_files << dump_pre_data_tables(base_file_name)
    counter = 1
    ActiveRecord::Base.connection.tables.each do | table_name |
      if TABLES_TO_BE_EXCLUDED.include? table_name
        next
      end

      puts "exporting data #{table_name}"
      dump_single_table(table_name, base_file_name, counter, created_at)
      counter += 1
    end 
    @outcome_files << dump_post_data_tables("#{base_file_name}_#{counter}")
  end  

  def dump_single_table(table_name, base_file_name, counter, time_stamp)
    outcome_from_single_tables = []
    table_base_name = "#{base_file_name}_#{counter >= 10 ? counter.to_s : '0'+counter.to_s}_#{table_name}"
    if require_to_be_anonymised?(table_name)
      outcome_from_single_tables = @anonymizer.anonymise_class(
        @anonymizer.tables_to_anonymised[table_name], table_base_name)
    else
      outcome_from_single_tables << dump_single_clear_table(table_name, table_base_name)      
    end
    compressed_files = compresssed_files(outcome_from_single_tables)
    if @where_to_stored == 'bucket'
      upload_to_s3(compressed_files, table_name, time_stamp)
    end
  end

  def compresssed_files(files)
    results = []
    files.each { | filename | results << DumperUtils.compress_file(filename) }
    results
  end

  def require_to_be_anonymised?(table_name)
    @anonymize && @anonymizer.tables_to_anonymised.keys().include?(table_name)
  end

  def dump_pre_data_tables(base_file_name)
    filename = "#{base_file_name}_00_pre_data.sql"
    command_line = "pg_dump #{@db_connection_url} -v --no-owner --no-privileges --no-password -O --section=pre-data -f #{filename}"
    result = system command_line
    raise 'Unable to execute pg_dump command' unless result == true
    filename 
  end

  def dump_post_data_tables(base_file_name)
    filename = "#{base_file_name}_post_data.sql"
    command_line = "pg_dump #{@db_connection_url} -v --no-owner --no-privileges --no-password -O --section=post-data -f #{filename}"
    result = system command_line
    raise 'Unable to execute pg_dump command' unless result == true
    filename 
  end

  def dump_single_clear_table(table_name, filename)
    # --column-inserts 
    command_line = "pg_dump #{@db_connection_url} -v --no-owner --no-privileges --no-password --data-only --table=#{table_name} -f #{filename}.sql"
    result = system command_line
    raise 'Unable to execute pg_dump command' unless result == true
    "#{filename}.sql"
  end

  def upload_to_s3(upload_files, table_name, created_at)
    if @s3_bucket
      compressed_files.each do | upload_file |
        @s3_bucket.put_object(
          "dumps/#{@tag}/#{upload_file}", 
          File.read(upload_file), 
          metadata: { "table" => table_name, "created_at" => created_at.to_s}
        )
      end
    end
  end 

end
