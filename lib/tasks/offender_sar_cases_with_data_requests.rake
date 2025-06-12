require "csv"
require "json"

namespace :links do
  desc "Generate a list of offender SAR cases with their data requests."
  task :generate, [:file] => :environment do |_task, _args|
    query = <<-SQL
      SELECT cases.*, data_requests.*
      FROM cases
      JOIN data_requests ON data_requests.case_id = cases.id
      WHERE cases.type = 'Case::SAR::Offender'
      AND cases.received_date >= '2018-01-01'
      AND cases.received_date <= '2024-09-30'
    SQL

    records_array = ActiveRecord::Base.connection.execute(query)
    result_file = "/tmp/offender_sar_cases_with_data_requests.csv"
    counter = 0

    CSV.open(result_file, "wb") do |csv|
      csv << ["ReqNo",
              "DPARefNo",
              "offender_case_number",
              "Exist?",
              "case_id",
              "subject_type",
              "date_of_birth",
              "subject_full_name",
              "subject_aliases",
              "subject_address",
              "prison_number",
              "other_subject_ids",
              "flag_as_high_profile",
              "data_request_id",
              "data_request_location",
              "data_request_date_requested"]

      records_array.each do |record|
        # Output case details
        puts "Case ID: #{record['id']}, Subject: #{record['subject_full_name']}, Address: #{record['subject_address']}"

        # Output data request details
        puts "Data Request ID: #{record['data_request_id']}, Location: #{record['location']}, Date Requested: #{record['date_requested']}"

        # Write to CSV
        csv << [record["number"],
                record["dpa_ref_no"],
                record["offender_case_number"],
                "Y",
                record["id"],
                record["subject_type"],
                record["date_of_birth"],
                record["subject_full_name"],
                record["subject_aliases"],
                record["subject_address"],
                record["prison_number"],
                record["other_subject_ids"],
                record["flag_as_high_profile"],
                record["data_request_id"],
                record["location"],
                record["date_requested"]]

        counter += 1
      end
    end

    puts "Total #{counter} Offender SAR cases and their data_requests."
  end
end
