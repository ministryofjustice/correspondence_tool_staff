require Rails.root.join("lib/tasks/rake_task_helpers/dumper_utils")
require Rails.root.join("lib/db/database_anonymizer")
require Rails.root.join("lib/db/users_settings_for_anonymizer")

class DatabaseAnonymizerTasks
  def initialize
    @s3_bucket = nil
    @tag = nil
    @is_store_to_s3_bucket = true
    @db_connection_url = nil
    @anonymizer = nil
    @task_arguments = nil
  end

  def execute_task(task_name, task_arguments)
    @task_arguments = task_arguments
    set_up_execute_variables(task_arguments)
    result_file = __send__(task_name, task_arguments)
    result_file = compresssed_file(result_file)
    if @is_store_to_s3_bucket
      upload_file_to_s3(result_file)
    end
    if Rails.env.production?
      FileUtils.rm(result_file)
    end
  end

  def store_anonymise_status(task_arguments, tasks)
    redis = Redis.new
    tasks_ids = tasks.map { |task| task[:task_id] }
    anonymizer_job_info = {
      "start_time": task_arguments[:timestamp],
      "tag": task_arguments[:tag],
      "number_of_tasks": tasks_ids.size,
      "tasks": tasks_ids,
    }
    anonymizer_job_id = "anonymizer_job_#{task_arguments[:tag]}_#{Time.zone.today.strftime('%Y%m%d')}"
    redis.set(anonymizer_job_id, anonymizer_job_info.to_json)
  end

private

  # Setup the variables requried for task

  def set_up_execute_variables(task_arguments)
    set_up_bucket
    @tag = task_arguments[:tag]
    @is_store_to_s3_bucket = task_arguments[:is_store_to_s3_bucket]
    @db_connection_url = task_arguments[:db_connection_url]
    created_at = task_arguments[:timestamp]
    @base_file_name = "#{@tag}_#{created_at}"
    user_settings_reader = UsersSettingsForAnonymizer.new
    user_settings_reader.load_user_settings_from_s3(@s3_bucket)
    @anonymizer = DatabaseAnonymizer.new(user_settings_reader, task_arguments[:limit])
  end

  def set_up_bucket
    bucket_key_id = @task_arguments[:s3_bucket_setting][:bucket_key_id]
    bucket_access_key = @task_arguments[:s3_bucket_setting][:bucket_access_key]
    bucket = @task_arguments[:s3_bucket_setting][:bucket]
    @s3_bucket = S3BucketHelper::S3Bucket.new(
      bucket_key_id,
      bucket_access_key,
      bucket:,
    )
  end

  # The actual function of processing different task

  def task_dump_schema_snapshot(_)
    filename = "#{@tag}_database_schema_snapshot.snap"
    command_line = "pg_dump #{@db_connection_url} -v --no-owner --no-privileges --no-password -s -f #{filename}"
    result = system command_line
    raise "Unable to execute pg_dump command" unless result == true

    filename
  end

  def task_dump_pre_data_tables(_)
    filename = "#{@base_file_name}_00_pre_data.sql"
    command_line = "pg_dump #{@db_connection_url} -v --no-owner --no-privileges --no-password -O --section=pre-data -f #{filename}"
    result = system command_line
    raise "Unable to execute pg_dump command" unless result == true

    filename
  end

  def task_dump_post_data_tables(task_arguments)
    counter = task_arguments[:counter]
    filename = "#{@base_file_name}_#{counter}_post_data.sql"
    command_line = "pg_dump #{@db_connection_url} -v --no-owner --no-privileges --no-password -O --section=post-data -f #{filename}"
    result = system command_line
    raise "Unable to execute pg_dump command" unless result == true

    filename
  end

  def task_dump_data_models_snapshot(_)
    filename = "#{@tag}_activerecord_models_snapshot.json"
    activerecord_models = {}
    Rails.application.eager_load! unless Rails.configuration.cache_classes
    ActiveRecord::Base.descendants.each do |activerecord_model|
      model_key = activerecord_model.name
      activerecord_models[model_key] = {
        "table_name" => activerecord_model.table_name,
        "attributes" => activerecord_model.new.attributes.keys,
      }
    rescue StandardError, NotImplementedError => e
      puts e.message
    end
    File.open(filename, "w") do |f|
      f.write(JSON.pretty_generate(activerecord_models))
    end
    filename
  end

  def task_dump_anonymised_table(task_arguments)
    table_name = task_arguments[:table]
    if table_name.blank?
      raise "No table name is provided"
    end

    counter = task_arguments[:counter]
    offset_counter = task_arguments[:offset_counter]
    number_of_groups = task_arguments[:number_of_groups]
    class_name = task_arguments[:class_name]
    model_class = class_name.constantize
    base_filename = "#{@base_file_name}_#{convert_counter_to_string(counter)}_#{table_name}"
    @anonymizer.anonymise_class_part(model_class, base_filename, number_of_groups, offset_counter)
  end

  def task_dump_clear_table(task_arguments)
    table_name = task_arguments[:table]
    if table_name.blank?
      raise "No table name is provided"
    end

    counter = task_arguments[:counter].to_i
    filename = "#{@base_file_name}_#{convert_counter_to_string(counter)}_#{table_name}"
    command_line = "pg_dump #{@db_connection_url} -v --no-owner --no-privileges --no-password --data-only --table=#{table_name} -f #{filename}.sql"
    result = system command_line
    raise "Unable to execute pg_dump command" unless result == true

    "#{filename}.sql"
  end

  def convert_counter_to_string(counter)
    counter >= 10 ? counter.to_s : "0#{counter}"
  end

  # The actual function of processing different task

  def compresssed_file(filename)
    DumperUtils.compress_file(filename)
  end

  def upload_file_to_s3(upload_file)
    DumperUtils.shell_working "Uploading #{upload_file} to bucket." do
      retries ||= 0
      actual_upload_file_name = File.basename(upload_file)
      response = @s3_bucket.put_object(
        "dumps/#{@tag}/#{actual_upload_file_name}",
        File.read(upload_file),
        metadata: { "created_at" => Time.zone.today.to_s },
      )
      if response && response["etag"].present?
        puts "done".green
      else
        puts "Failed to upload this file, the response is #{response}"
        raise "Failed to upload #{upload_file}, will try again!"
      end
    rescue StandardError
      set_up_bucket
      retry if (retries += 1) < 2
    end
  end
end
