require "csv"
require "json"

query = <<-SQL
  SELECT cases.properties->>'case_reference_number' AS case_reference_number,
         cases.number AS case_number,
         data_request_areas.data_request_area_type,
         cases.received_date,
         cases.type,
         cases.properties,
         data_request_areas.location,
         data_requests.request_type,
         data_requests.request_type_note,
         data_requests.date_requested,
         data_requests.date_from,
         data_requests.date_to,
         data_requests.cached_num_pages,
         data_requests.cached_date_received
  FROM cases
  LEFT JOIN data_requests ON cases.id = data_requests.case_id
  LEFT JOIN data_request_areas ON data_requests.data_request_area_id = data_request_areas.id
  WHERE cases.type = 'Case::SAR::Offender'
    AND cases.received_date >= '2018-01-01'
    AND cases.received_date <= '2024-09-30'
  ORDER BY (properties->>'case_reference_number')::text
SQL

namespace :dps do
  desc "List DPS cases with data requests"
  task list_cases: :environment do |_task|
    result_file = "tmp/offender_sar_cases_with_data_requests.csv"
    records_array = ActiveRecord::Base.connection.execute(query)
    counter = 0

    CSV.open(result_file, "wb") do |csv|
      # Define headers
      csv << %w[
        case_reference_number
        case_number
        received_date
        type
        requester_subject_full_name
        subject_aliases
        date_of_birth
        prison_number
        other_subject_ids
        previous_case_numbers
        subject_type
        third_party_company_name
        requester_third_party_name
        third_party_address
        data_request_area_location
        data_request_area_type
        request_type
        request_type_note
        date_requested
        date_from
        date_to
        number_final_pages,
        cached_date_received
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

        # Write data to CSV
        csv << [
          json_data["case_reference_number"],
          record["case_number"],
          record["received_date"],
          record["type"],
          json_data["subject_full_name"],
          json_data["subject_aliases"],
          json_data["date_of_birth"],
          json_data["prison_number"],
          json_data["other_subject_ids"],
          json_data["previous_case_numbers"],
          json_data["subject_type"],
          json_data["third_party_company_name"],
          json_data["third_party_name"],
          json_data["third_party_address"],
          record["data_request_area_location"],
          record["data_request_area.data_request_area_type"],
          record["request_type"],
          record["request_type_note"],
          record["date_requested"],
          record["date_from"],
          record["date_to"],
          record["cached_num_pages"],
          record["cached_date_received"],
        ]
        counter += 1
      end
    end

    puts "#{counter} offender SAR cases with data requests listed in #{result_file}"
  end
end
