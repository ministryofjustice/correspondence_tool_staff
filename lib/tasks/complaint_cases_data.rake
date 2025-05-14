require "csv"
require "json"

def fake_offender_complaint_data_object(record)
  record.delete("id")
  record.delete("document_tsvector")
  properties = JSON.parse(record["properties"])
  record.delete("properties")
  original_case = Case::Base.find(record["linked_case_id"])
  record["original_case"] = original_case
  record.delete("linked_case_id")
  properties.each do |key, value|
    record[key] = value
  end
  Case::SAR::OffenderComplaint.new(record)
end

def locate_offender_sar_case(dpa_ref_no)
  offender = Case::SAR::Offender.find_by_number("MIG#{dpa_ref_no}")
  if offender.nil?
    offender = Case::SAR::Offender.find_by_number(dpa_ref_no)
  end
  if offender.nil? && dpa_ref_no.length > 5
    offenders = Case::SAR::Offender.where("number like ? ", "%#{dpa_ref_no}")
    offender = offenders.first unless offenders.count > 1
  end
  offender
end

namespace :complaints do
  namespace :links do
    desc "Check whether the offender sar being referred to in Complaint case exists in DB or not."
    task :check, [:file] => :environment do |_task, args|
      raise "Must specify the csv file containing the list of complaint cases" if args[:file].blank?
      raise "The file doesn't exist" unless File.file?(args[:file])

      result_file = "#{args[:file].gsub('.csv', '')}_checking_result.csv"
      puts result_file
      counter = 1
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
                "flag_as_dps_missing_data"]
        CSV.foreach(args[:file], headers: true) do |row|
          puts "Checking #{row['DPARefNo']}"
          offender = locate_offender_sar_case(row["DPARefNo"])
          csv << [row["ReqNo"],
                  row["DPARefNo"],
                  (offender.present? ? offender.number : ""),
                  (offender.present? ? "Y" : "N"),
                  (offender.present? ? offender.id : ""),
                  (offender.present? ? offender.subject_type : ""),
                  (offender.present? ? offender.date_of_birth : ""),
                  (offender.present? ? offender.subject_full_name : ""),
                  (offender.present? ? (offender.subject_aliases || "") : ""),
                  (offender.present? ? offender.subject_address : ""),
                  (offender.present? ? offender.prison_number : ""),
                  (offender.present? ? (offender.other_subject_ids || "") : ""),
                  (offender.present? ? offender.flag_as_high_profile : ""),
                  (offender.present? ? offender.flag_as_dps_missing_data : "")]
          counter += 1 if offender.blank?
        end
      end
      puts "Totally #{counter} complaints cases couldn't find the linked offender SAR case."
    end
  end

  namespace :validation do
    desc "Validate whether the migrated complaint pass the validation of Complaint Model."
    task :validate, [:file] => :environment do |_task, args|
      raise "Must specify the csv file for outputing the result " if args[:file].blank?

      counter = 0

      CSV.open(args[:file], "wb") do |csv|
        csv << %w[complaint_case_number errors]
        counter = 0
        query = <<-SQL
                  SELECT cases.*, linked_cases.linked_case_id
                  FROM cases join linked_cases on cases.id = linked_cases.case_id#{' '}
                  WHERE cases.type = 'Case::SAR::OffenderComplaint' and linked_cases.type='original'
        SQL
        records_array = ActiveRecord::Base.connection.execute(query)
        records_array.each do |record|
          puts "Checking complaint #{record['number']}"
          begin
            complaint = fake_offender_complaint_data_object(record)
            unless complaint.valid?
              errors = complaint.errors.full_messages.clone
              errors.delete("External deadline cannot be in the past")
              if errors.present?
                counter += 1
                csv << [record["number"], complaint.errors.full_messages]
              end
            end
          rescue StandardError => e
            counter += 1
            csv << [record["number"], e.message]
          end
        end
      end
      puts "Totally #{counter} complaints cases couldn't pass the validation."
    end
  end
end
