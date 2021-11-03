#  This class is to provide easy functin to get the data out of environent and anonymize them
#  initial plan is to not provide clear option
#
require File.join(Rails.root, 'lib', 'tasks', 'rake_task_helpers', 'dumper_utils')
require File.join(Rails.root, 'lib', 'db', 'database_anonymizer_tasks')


class DatabaseDumper

  attr_reader :outcome_files, :bucket_key_id, :bucket_access_key, :bucket

  MAX_NUM_OF_RECORDS_PER_GROUP = 10000
  TABLES_TO_BE_EXCLUDED = ["reports", "search_queries", "sessions", "versions"]
  CLASSES_TO_ANONYMISE = [Team, TeamProperty, ::Warehouse::CaseReport, Case::Base, User, CaseTransition, CaseAttachment]


  def initialize(tag, is_store_to_s3_bucket, s3_bucket: nil, running_mode: 'simple')
    @anonymizer = nil
    @db_connection_url = ENV['DATABASE_URL'] || 'postgres://localhost/correspondence_platform_development'
    @s3_bucket = s3_bucket
    @tag = tag
    @is_store_to_s3_bucket = is_store_to_s3_bucket

    @running_mode = running_mode
    @tasks = nil
    @dirname = "./dumps_#{@tag}"
    @tables_to_anonymised = {}
    CLASSES_TO_ANONYMISE.each { |klass| @tables_to_anonymised[klass.table_name] = klass }
  end

  def run
    plan_tasks(pack_task_arguments)
    # dump_schema_snapshot(dirname)
    # dump_data_models_snapshot(dirname)
    # dump_local_database(dirname)
    # if @s3_bucket
    #   upload_to_s3(dirname)
    # end
    # @outcome_files
    trigger_tasks
  end

  private

  def init_dump_environment
    FileUtils.rm_rf(@dirname)
    FileUtils.mkpath(@dirname)
  end

  def plan_tasks(task_arguments)
    add_initial_tasks(task_arguments)
    add_tables_tasks(task_arguments)
  end 

  def trigger_tasks
    @tasks.each do | task | 
      AnonymiserDBJob.perform_later(task['task_function'], task)
    end 
  end 

  def pack_task_arguments
    {
      "db_connection_url": @db_connection_url
    }
  end

  def add_initial_tasks(task_arguments)
    arguments = task_arguments.clone
    arguments["task_function"] = "task_dump_schema_snapshot"
    arguments["task_id"] = "task_dump_schema_snapshot"
    @task << arguments

    arguments = task_arguments.clone
    arguments["task_function"] = "task_dump_data_models_snapshot"
    arguments["task_id"] = "task_dump_data_models_snapshot"
    @task << arguments

    arguments = task_arguments.clone
    arguments["task_function"] = "task_dump_pre_data_tables"
    arguments["task_id"] = "task_dump_pre_data_tables"
    @task << arguments
  end 

  def add_tables_tasks(task_arguments)
    ActiveRecord::Base.connection.tables.each do | table_name |
      if TABLES_TO_BE_EXCLUDED.include? table_name
        next
      end
      if require_to_be_anonymised?(table_name)
        add_anoymised_table_tasks(task_arguments, table_name)
      else
        add_clear_table_task(task_arguments, table_name)
      end
      counter += 1
    end 
  end

  def add_clear_table_task(task_arguments, table_name)
    arguments = task_arguments.clone
    arguments['table'] = table_name
    arguments['task_function'] = "task_dump_clear_table"
    arguments['task_id'] = "task_dump_clear_table"
    @tasks << arguments
  end

  def add_anoymised_table_tasks(task_arguments, table_name)
    number_of_groups = cal_number_of_groups(@tables_to_anonymised[table_name])
    number_of_groups.times do | counter |
      arguments = task_arguments.clone
      arguments['table'] = table_name
      arguments['counter'] = counter
      arguments['class_name'] = @tables_to_anonymised[table_name].to_s
      arguments['offset'] = MAX_NUM_OF_RECORDS_PER_GROUP * counter
      arguments['task_function'] = "task_dump_anonymised_table"
      arguments['task_id'] = "task_dump_anonymised_table_#{counter}"
      @tasks << arguments
    end    
  end

  def require_to_be_anonymised?(table_name)
    @anonymize && @tables_to_anonymised.keys().include?(table_name)
  end

  def cal_number_of_groups(klass)
    (Float(klass.all.count)/MAX_NUM_OF_RECORDS_PER_GROUP).ceil()
  end

end
