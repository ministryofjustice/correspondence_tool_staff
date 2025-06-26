#  This class is to provide easy functin to get the data out of environent and anonymize them
#  initial plan is to not provide clear option
#
require Rails.root.join("lib/tasks/rake_task_helpers/dumper_utils")
require Rails.root.join("lib/db/database_anonymizer_tasks")

class DatabaseDumper
  attr_reader :outcome_files, :bucket

  MAX_NUM_OF_RECORDS_PER_GROUP = 10_000
  TABLES_TO_BE_EXCLUDED = %w[reports search_queries sessions versions].freeze
  CLASSES_TO_ANONYMISE = [Team, TeamProperty, ::Warehouse::CaseReport, Case::Base, User, CaseTransition, CaseAttachment, Contact].freeze

  def initialize(tag, running_mode = "tasks", is_store_to_s3_bucket: true, s3_bucket_setting: nil)
    ####
    # tag:  part of the file name for  the anonymised data, it is ID of the anonymised db copy on s3 bucket
    # is_store_to_s3_bucket: this flag is default to true, if you want to debug it at local, you can turn it off
    # s3_bucket_setting: nil, this setting need to be provided if is_store_to_s3_bucket
    # running_mode: tasks: run those tasks in the background, other value will turn it off
    ####
    @s3_bucket_setting = s3_bucket_setting
    @tag = tag
    @is_store_to_s3_bucket = is_store_to_s3_bucket
    @running_mode = running_mode

    init_dump_environment
  end

  def run
    task_arguments = pack_task_arguments
    plan_tasks(task_arguments)
    DatabaseAnonymizerTasks.new.store_anonymise_status(task_arguments, @tasks)
    trigger_tasks
  end

private

  def init_dump_environment
    @db_connection_url = ENV["DATABASE_URL"] || "postgres://localhost/correspondence_platform_development"
    @dirname = "./dumps_#{@tag}"
    @tasks = []
    @tables_to_anonymise = {}
    CLASSES_TO_ANONYMISE.each { |klass| @tables_to_anonymise[klass.table_name] = klass }
    @timestamp = Time.zone.now.strftime("%Y%m%d-%H%M%S")
  end

  def pack_task_arguments
    {
      "db_connection_url": @db_connection_url,
      "dir_name": @dirname,
      "is_store_to_s3_bucket": @is_store_to_s3_bucket,
      "tag": @tag,
      "timestamp": @timestamp,
      "s3_bucket_setting": @s3_bucket_setting,
    }
  end

  def plan_tasks(task_arguments)
    add_initial_tasks(task_arguments)
    table_counter = add_tables_tasks(task_arguments)
    add_end_tasks(task_arguments, table_counter)
  end

  def trigger_tasks
    @tasks.each do |task|
      if @running_mode == "tasks"
        AnonymiserDbJob.perform_later(task[:task_function], task)
      else
        DatabaseAnonymizerTasks.new.execute_task(task[:task_function], task)
      end
    end
  end

  def add_initial_tasks(task_arguments)
    arguments = task_arguments.clone
    arguments[:task_function] = "task_dump_schema_snapshot"
    arguments[:task_id] = "task_dump_schema_snapshot"
    @tasks << arguments

    arguments = task_arguments.clone
    arguments[:task_function] = "task_dump_data_models_snapshot"
    arguments[:task_id] = "task_dump_data_models_snapshot"
    @tasks << arguments

    arguments = task_arguments.clone
    arguments[:task_function] = "task_dump_pre_data_tables"
    arguments[:task_id] = "task_dump_pre_data_tables"
    @tasks << arguments
  end

  def add_end_tasks(task_arguments, table_counter)
    arguments = task_arguments.clone
    arguments[:task_function] = "task_dump_post_data_tables"
    arguments[:counter] = table_counter
    arguments[:task_id] = "task_dump_post_data_tables"
    @tasks << arguments
  end

  def add_tables_tasks(task_arguments)
    table_counter = 1
    ActiveRecord::Base.connection.tables.each do |table_name|
      if TABLES_TO_BE_EXCLUDED.include? table_name
        next
      end

      if require_to_be_anonymised?(table_name)
        add_anoymised_table_tasks(task_arguments, table_name, table_counter)
      else
        add_clear_table_task(task_arguments, table_name, table_counter)
      end
      table_counter += 1
    end
    table_counter
  end

  def add_clear_table_task(task_arguments, table_name, table_counter)
    arguments = task_arguments.clone
    arguments[:table] = table_name
    arguments[:counter] = table_counter
    arguments[:task_function] = "task_dump_clear_table"
    arguments[:task_id] = "task_dump_clear_table"
    @tasks << arguments
  end

  def add_anoymised_table_tasks(task_arguments, table_name, table_counter)
    number_of_groups = cal_number_of_groups(@tables_to_anonymise[table_name])
    number_of_groups.times do |counter|
      arguments = task_arguments.clone
      arguments[:table] = table_name
      arguments[:counter] = table_counter
      arguments[:offset_counter] = counter
      arguments[:number_of_groups] = number_of_groups
      arguments[:class_name] = @tables_to_anonymise[table_name].to_s
      arguments[:limit] = MAX_NUM_OF_RECORDS_PER_GROUP
      arguments[:task_function] = "task_dump_anonymised_table"
      arguments[:task_id] = "task_dump_anonymised_table_#{counter}"
      @tasks << arguments
    end
  end

  def require_to_be_anonymised?(table_name)
    @tables_to_anonymise.keys.include?(table_name)
  end

  def cal_number_of_groups(klass)
    (Float(klass.all.count) / MAX_NUM_OF_RECORDS_PER_GROUP).ceil
  end
end
