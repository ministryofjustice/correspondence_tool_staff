#  This class is to provide easy functin to get the data out of environent and anonymize them
#  initial plan is to not provide clear option
#
#
# require 'colorize'
# require 'shell-spinner'


class DatabaseDumper

  attr_reader :outcome_files

  TABLES_TO_BE_EXCLUDED = ["reports", "search_queries", "sessions"]

  def initialize(anonymize)
    @anonymize = anonymize
    @db_connection_url = ENV['DATABASE_URL'] || 'postgres://localhost/correspondence_platform_development'
    @s3_bucket = S3BucketHelper::S3Bucket.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"])
    @outcome_files = []
  end

  def run
    dump_local_database
    @outcome_files
  end

  private

  def dump_local_database
    require File.expand_path(File.dirname(__FILE__) + '/../../lib/db/database_anonymizer')

    @anonymizer = DatabaseAnonymizer.new()
    created_at = Time.now.strftime('%Y%m%d-%H%M%S')
    base_file_name = "#{Rails.env}_#{created_at}"

    dump_pre_data_tables(base_file_name)
    # dump_sequences_tables(base_file_name)
    counter = 2
    ActiveRecord::Base.connection.tables.each do | table_name |
      if TABLES_TO_BE_EXCLUDED.include? table_name
        next
      end

      table_base_file_name = "#{base_file_name}_#{counter > 10 ? counter.to_s : '0'+counter.to_s}"
      byebug
      if @anonymize && @anonymizer.tables_to_anonymised.keys().include?(table_name)

        table_final_name = @anonymizer.anonymise_class(
          @anonymizer.tables_to_anonymise[table_name], 
          table_base_file_name)
        compressed_file = compress_file(table_final_name)
        upload_to_s3(compressed_file, table_name, created_at)
      else
        table_final_name = dump_single_table(table_name, table_base_file_name)
        compressed_file = compress_file(table_final_name)
      end

      @outcome_files << table_final_name
      counter += 1
    end 
    dump_post_data_tables("#{base_file_name}_#{counter}")
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

  def dump_single_table(table_name, table_base_file_name)
    filename = "#{table_base_file_name}_#{table_name}.sql"
    command_line = "pg_dump #{@db_connection_url} -v --no-owner --no-privileges --no-password --column-inserts --data-only --table=#{table_name} -f #{filename}"
    result = system command_line
    raise 'Unable to execute pg_dump command' unless result == true
    filename 
  end

  def upload_to_s3(upload_file, table_name, created_at)
    if @s3_bucket
      @s3_bucket.put_object(
        compressed_file, 
        File.read(compressed_file), 
        { "table" => table_name, "created_at" => created_at.to_s}
      )
    end
  end 

end
