require "csv"
require "json"

query = <<-SQL
  SELECT cases.id,
         cases.received_date,
         cases.type,
         cases.properties,
         data_requests.location,
         data_requests.request_type,
         data_requests.request_type_note,
         data_requests.date_requested,
         data_requests.date_from,
         data_requests.date_to,
         data_requests.cached_num_pages,
         data_requests.completed
  FROM cases
  LEFT JOIN data_requests ON cases.id = data_requests.case_id
  WHERE cases.type = 'Case::SAR::Offender'
    AND cases.received_date >= '2018-01-01'
    AND cases.received_date <= '2024-09-30'
SQL

namespace :dps do
  desc "List DPS cases with data requests"
  task list_cases: :environment do |_task|
    result_file = "/tmp/offender_sar_cases_with_data_requests.csv"
    records_array = ActiveRecord::Base.connection.execute(query)
    counter = 0

    CSV.open(result_file, "wb") do |csv|
      # Define headers
      csv << %w[
        case_id
        received_date
        type
        subject_full_name
        subject_aliases
        subject_address
        date_of_birth
        prison_number
        other_subject_ids
        previous_case_numbers
        subject_type
        recipient
        third_party_company_name
        location
        request_type
        request_type_note
        date_requested
        date_from
        date_to
        cached_num_pages
        completed
      ]

      puts "Writing offender SAR cases with data requests to #{result_file}"
      puts "Total records found: #{records_array.count}"

      records_array.each do |record|
        # Parse JSON properties
        json_data = begin
          JSON.parse(record["properties"])
        rescue StandardError
          {}
        end

        # Remove new lines and carriage returns from all string values in json_data
        json_data.each do |key, value|
          json_data[key] = value.is_a?(String) ? value.gsub(/[\n\r]/, " ") : value
        end

        # Remove new lines and carriage returns from subject_address
        subject_address = json_data["subject_address"].is_a?(String) ? json_data["subject_address"].gsub(/[\n\r]/, " ") : json_data["subject_address"]

        # Write data to CSV
        csv << [
          record["id"],
          record["received_date"],
          record["type"],
          json_data["subject_full_name"],
          json_data["subject_aliases"],
          subject_address, # Processed subject_address
          json_data["date_of_birth"],
          json_data["prison_number"],
          json_data["other_subject_ids"],
          json_data["previous_case_numbers"],
          json_data["subject_type"],
          json_data["recipient"],
          json_data["third_party_company_name"],
          record["location"],
          record["request_type"],
          record["request_type_note"],
          record["date_requested"],
          record["date_from"],
          record["date_to"],
          record["cached_num_pages"],
          record["completed"],
        ]
        counter += 1
      end
    end

    puts "#{counter} offender SAR cases with data requests listed in #{result_file}"
  end
end
