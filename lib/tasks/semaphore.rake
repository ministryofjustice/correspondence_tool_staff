# The reason for the rake test is that semaphore seems to either use its own
# database.yml file or extends our Database. Whatever it does it does not create
# a DB using 'correspondence_platform_test'
#
# Created database '4576c3eb-xxx_test'
# Created database '4576c3eb-xxx_test2'
# Created database '4576c3eb-xxx_test3'
# Created database '4576c3eb-xxx_test4'
# The rake test is called inside a semaphore job.
# https://semaphoreci.com/aliuk2012/correspondence_tool_staff/settings

namespace :semaphore do
  desc "prepare db config"
  task prepare_db_config: :environment do |_t, _args|
    file_name = "config/database.yml"
    db_suffix = "<%= ENV['TEST_ENV_NUMBER'] %>"
    database_yml = YAML.load_file(file_name)

    unless database_yml["test"]["database"].ends_with? db_suffix
      database_yml["test"]["database"] += db_suffix
    end
    File.open(file_name, "w") { |f| f.write database_yml.to_yaml }
  end
end
