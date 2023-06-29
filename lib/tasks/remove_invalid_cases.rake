require "csv"
require "json"

def is_on_production?
  ENV["ENV"].present? && ENV["ENV"] == "prod"
end

def cases_scope
  query = <<-SQL
            SELECT cases.*, origin_linked_cases.linked_case_id
            FROM cases left join#{' '}
            (select * from linked_cases where linked_cases.type='original') as origin_linked_cases#{' '}
            on cases.id = origin_linked_cases.case_id#{' '}
            WHERE cases.deleted = false
  SQL
  ActiveRecord::Base.connection.execute(query)
end

def validate_case(record)
  errors = []
  begin
    kase = fake_case_data_object(record)
    unless kase.valid?
      errors = kase.errors.full_messages.clone
      errors = remove_invalid_error_messages(errors)
    end
  rescue StandardError => e
    errors << e.message
  end
  if errors.empty?
    kase = Case::Base.find_by_number(record["number"])
    if kase.present? && kase.managing_team.nil?
      errors << "This case doesn't have managing_team"
    end
  end
  errors
end

def remove_invalid_error_messages(errors)
  allowed_errors = [
    "External deadline cannot be in the past",
    "Received date is too far in the past",
    "Received date too far in past.",
    "Final deadline cannot be in the past",
    "unknown attribute 'reply_method' for Case::SAR::Offender.",
    " No ICO decision files have been uploaded",
  ]
  actual_errors = []
  errors.each do |error|
    actual_errors << error unless allowed_errors.include?(error)
  end
  actual_errors
end

def fake_case_data_object(record)
  record.delete("id")
  record.delete("document_tsvector")
  properties = JSON.parse(record["properties"])
  record.delete("properties")
  if record["linked_case_id"].present?
    original_case = Case::Base.find(record["linked_case_id"])
    record["original_case"] = original_case
  end
  record.delete("linked_case_id")
  if ["Case::ICO::FOI", "Case::ICO::SAR"].include?(record["type"])
    record.delete("name")
    record.delete("subject")
  end
  properties.each do |key, value|
    record[key] = value
  end
  case_class = record["type"].constantize
  case_class.new(record)
end

def remove_case(case_id)
  ActiveRecord::Base.transaction do
    query = "delete from case_transitions where case_id = #{case_id};"
    ActiveRecord::Base.connection.execute(query)
    query = "delete from cases_exemptions where case_id = #{case_id};"
    ActiveRecord::Base.connection.execute(query)
    query = "delete from case_attachments where case_id = #{case_id};"
    ActiveRecord::Base.connection.execute(query)
    query = "delete from data_requests where case_id = #{case_id};"
    ActiveRecord::Base.connection.execute(query)
    query = "delete from data_requests where case_id = #{case_id};"
    ActiveRecord::Base.connection.execute(query)
    query = "delete from linked_cases where case_id = #{case_id};"
    ActiveRecord::Base.connection.execute(query)
    query = "delete from linked_cases where linked_case_id = #{case_id};"
    ActiveRecord::Base.connection.execute(query)
    query = "delete from warehouse_case_reports where case_id = #{case_id};"
    ActiveRecord::Base.connection.execute(query)
    query = "delete from cases where id = #{case_id};"
    ActiveRecord::Base.connection.execute(query)
  end
end

def question_user(query)
  print query
  input = $stdin.gets.chomp
  if input.downcase.start_with?("n") || input.nil?
    puts "exiting"
    exit
  end
end

namespace :cases do
  namespace :validation do
    desc "Validate whether the case in database meets the validation of Case Model."
    task :validate, [:file] => :environment do |_task, args|
      raise "Must specify the csv file for outputing the result " if args[:file].blank?

      counter = 0

      CSV.open(args[:file], "wb") do |csv|
        csv << %w[case_number errors]
        counter = 0
        records_array = cases_scope
        records_array.each do |record|
          puts "Checking case #{record['number']}"
          errors = validate_case(record)
          if errors.present?
            counter += 1
            csv << [record["number"], errors]
          end
        end
      end
      puts "Totally #{counter} cases couldn't pass the validation."
    end

    desc "Remove invalid case based on the validation of Case Model."
    task remove: :environment do
      if is_on_production?
        puts "Cannot run this command on production environment!"
      else
        question_user("Are you sure this is not production env and want to remove those invalid cases (y/n)?")
        counter = 0
        records_array = cases_scope
        records_array.each do |record|
          puts "Checking case #{record['number']}"
          case_id = record["id"]
          errors = validate_case(record)
          next if errors.blank?

          counter += 1
          remove_case(case_id)
          puts "Removed case #{record['number']}"
        end
      end
      puts "Totally #{counter} invalid cases have been removed."
    end
  end
end
