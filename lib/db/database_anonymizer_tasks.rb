class DatabaseAnonymizerTasks


  def initialize
    @s3_bucket = nil
    @tag = nil
    @is_store_to_s3_bucket = true
    @dirname = nil
    @db_connection_url = nil
  end

  def execute_task(task_name, task_arguments)
    begin
      set_up_execute_variables(task_arguments)
      result_file = self.__send__(task_name, task_arguments)
      result_file = compresssed_file(result_file)
      upload_file_to_s3(result_file)
    rescue
    end 
  end
  
  private 

  def is_anoymised_job_done?
    redis = Redis.new
    redis.get(report.guid)
  end

  def save_info(info_key, content)
    redis = Redis.new
    redis.set(info_key, content)
  end

  # Setup the variables requried for task

  def set_up_execute_variables(task_arguments)
    set_up_bucket(task_arguments)
    @tag = task_arguments['tag']
    @is_store_to_s3_bucket = task_arguments['is_store_to_s3_bucket']
    @db_connection_url = task_arguments['db_connection_url']
    @dirname = task_arguments['dirname']
    created_at = Time.now.strftime('%Y%m%d-%H%M%S')
    @base_file_name = "#{@dirname}/#{@tag}_#{created_at}"
  end

  def set_up_bucket(task_arguments)
    bucket_key_id = task_arguments['bucket_key_id'] || ENV["AWS_ACCESS_KEY_ID"]
    bucket_access_key = task_arguments['bucket_access_key'] || ENV["AWS_SECRET_ACCESS_KEY"]
    bucket = task_arguments['bucket'] || Settings.case_uploads_s3_bucket
    @s3_bucket = S3BucketHelper::S3Bucket.new(
      bucket_key_id, 
      bucket_access_key,
      bucket: bucket)
  end 

  # The actual function of processing different task 

  def task_dump_schema_snapshot(task_arguments)
    filename = "#{dirname}/#{@tag}_database_schema_snapshot.snap"
    command_line = "pg_dump #{@db_connection_url} -v --no-owner --no-privileges --no-password -s -f #{filename}"
    result = system command_line
    raise 'Unable to execute pg_dump command' unless result == true
    filename
  end

  def task_dump_pre_data_tables(task_arguments)
    filename = "#{@base_file_name}_00_pre_data.sql"
    command_line = "pg_dump #{@db_connection_url} -v --no-owner --no-privileges --no-password -O --section=pre-data -f #{filename}"
    result = system command_line
    raise 'Unable to execute pg_dump command' unless result == true
    filename 
  end

  def task_dump_post_data_tables(task_arguments)
    filename = "#{@base_file_name}_post_data.sql"
    command_line = "pg_dump #{@db_connection_url} -v --no-owner --no-privileges --no-password -O --section=post-data -f #{filename}"
    result = system command_line
    raise 'Unable to execute pg_dump command' unless result == true
    filename 
  end

  def task_dump_data_models_snapshot(task_arguments)
    filename = "#{@dirname}/#{@tag}_activerecord_models_snapshot.json"
    activerecord_models = {}
    Rails.application.eager_load! unless Rails.configuration.cache_classes
    ActiveRecord::Base.descendants.each do | activerecord_model |
      begin
        model_key = activerecord_model.name
        activerecord_models[model_key] = {
          "table_name" => activerecord_model.table_name, 
          "attributes" => activerecord_model.new.attributes.keys
        }  
      rescue NotImplementedError
        false
      end
    end
    File.open(filename, "w") do |f|
      f.write(JSON.pretty_generate(activerecord_models))
    end
    filename
  end

  def task_dump_anonymised_table(table_name, base_file_name, counter)
    table_name = task_arguments['table_name']
    counter = task_arguments['counter']
    class_name = task_arguments['class_name']
    model_class = class_name.constantize
    base_filename = "#{base_file_name}_#{counter >= 10 ? counter.to_s : '0'+counter.to_s}_#{table_name}"
    filename = @anonymizer.anonymise_class(model_class, base_filename)
  end

  def task_dump_clear_table(task_arguments)
    table_name = task_arguments['table_name']
    counter = task_arguments['counter']
    filename = "#{@base_file_name}_#{table_name}"
    command_line = "pg_dump #{@db_connection_url} -v --no-owner --no-privileges --no-password --data-only --table=#{table_name} -f #{filename}.sql"
    result = system command_line
    raise 'Unable to execute pg_dump command' unless result == true
    "#{filename}.sql"
  end

   # The actual function of processing different task 
 
  def compresssed_file(filename)
    DumperUtils.compress_file(filename)
  end

  def upload_file_to_s3(upload_file)
    DumperUtils.shell_working "Uploading #{upload_file} to bucket." do
      begin 
        retries ||= 0
        actual_upload_file_name = File.basename(upload_file)
        response = @s3_bucket.put_object(
          "dumps/#{@tag}/#{actual_upload_file_name}", 
          File.read(upload_file), 
          metadata: {"created_at" => Date.today.to_s}
        )
        if respondse && response['ETag'].present?
          puts 'done'.green
        else
          puts "Failed to upload this file, the response is #{response}"
          raise "Failed to upload #{upload_file}, will try again!"
        end
      rescue
        init_s3_bucket
        retry if (retries += 1) < 2
      end
    end
  end


end
