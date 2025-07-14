require "csv"
require "json"

query = <<-SQL
  SELECT TO_CHAR(cases.received_date, 'DD/MM/YYYY') as date_received,
         cases.number,
         cases.type,
         cases.properties->>'subject_full_name' as full_name,
         cases.properties->>'subject_aliases' as "alias",
         cases.properties->>'date_of_birth' as date_of_birth,
         cases.properties->>'previous_case_numbers' as previous_case_numbers,
         cases.properties->>'prison_number' as prison_number,
         cases.properties->>'other_subject_ids' as pcn,
         cases.properties->>'case_reference_number' as crn,
         cases.properties->>'subject_type' as subject_type,
         CASE WHEN (cases.properties->>'third_party')::boolean = true THEN 'Solicitor/other' ELSE 'Data subject' END AS requester,
         cases.properties->>'third_party_name' as third_party_name,
         cases.properties->>'third_party_company_name' as third_party_company_name,
         cases.postal_address as postal_address,
         cases.properties->>'subject_address' as subject_address,
         dr.location as request_location,
         contacts.name as request_location_two,
         dr.request_type as request_type,
         dr.request_type_note as request_type_note,
         TO_CHAR(dr.date_requested, 'DD/MM/YYYY') as date_requested,
         TO_CHAR(dr.date_from, 'DD/MM/YYYY') as date_from,
         TO_CHAR(dr.date_to, 'DD/MM/YYYY') as date_to,
         dr.cached_num_pages as pages,
         CASE WHEN dr.completed = true THEN 'Yes' ELSE 'No' END AS completed,
         CASE WHEN dr.cached_date_received IS NULL THEN 'No date recorded' ELSE TO_CHAR(dr.cached_date_received, 'DD/MM/YYYY') END as completed_date
  FROM cases
  LEFT JOIN data_requests AS dr ON dr.case_id = cases.id
  LEFT JOIN data_request_areas AS dra ON dr.data_request_area_id = dra.id
  LEFT JOIN contacts ON dra.contact_id = contacts.id
  WHERE cases.type = 'Case::SAR::Offender'
    AND cases.received_date >= '2018-01-01'
    AND cases.received_date <= '2024-09-30'
  ORDER BY cases.number ASC;
SQL

namespace :dps do
  desc "List DPS cases with data requests"
  task list_cases: :environment do |_task|
    result_file = "tmp/offender_sar_cases_with_data_requests.csv"
    records_array = ActiveRecord::Base.connection.execute(query)
    counter = 0

    CSV.open(result_file, "wb") do |csv|
      # Define headers
      csv << [
        "Date Received",
        "Case Number",
        "Case Type",
        "Full Name of Subject",
        "Alias",
        "Date of Birth",
        "Previous SAR Case Numbers",
        "Prison Number",
        "PCN",
        "CRN",
        "Subject Type",
        "Requester",
        "Third Party Name",
        "Third Party Company Name",
        "Postal Address",
        "Subject Address",
        "Location",
        "Location two",
        "Data Request Type",
        "Request Type Note",
        "Date Requested",
        "Date From",
        "Date To",
        "Pages Received",
        "Completed",
        "Data Request Completed Date",
      ]

      puts "Writing offender SAR cases with data requests to #{result_file}"
      puts "Total records found: #{records_array.count}"

      records_array.each do |record|
        # Write data to CSV
        csv << [
          record["date_received"],
          record["number"],
          record["type"],
          record["full_name"],
          record["alias"],
          record["date_of_birth"],
          record["previous_case_numbers"],
          record["prison_number"],
          record["pcn"],
          record["crn"],
          record["subject_type"],
          record["requester"],
          record["third_party_name"],
          record["third_party_company_name"],
          record["postal_address"],
          record["subject_address"],
          record["request_location"],
          record["request_location_two"],
          record["request_type"],
          record["request_type_note"],
          record["date_requested"],
          record["date_from"],
          record["date_to"],
          record["pages"],
          record["completed"],
          record["completed_date"],
        ]
        counter += 1
      end
    end
    puts "#{counter} offender SAR cases with data requests listed in #{result_file}"
  end
end
