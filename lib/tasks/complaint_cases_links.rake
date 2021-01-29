require 'csv'

namespace :complaints do
  namespace :links do

    desc "Check whether the offender sar being referred to in Complaint case exists in DB or not."
    task :check, [:file] => :environment do |_task, args|
      raise "Must specify the csv file containing the list of complaint cases" if args[:file].blank?    
      raise "The file doesn't exist" if !File.file?(args[:file])
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
                "flag_as_high_profile"]
        CSV.foreach(args[:file], headers: true) do |row|
          puts "Checking #{row['DPARefNo']}"
          offender = locate_offender_sar_case(row['DPARefNo'])
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
                  (offender.present? ? offender.flag_as_high_profile : "")]
          counter += 1 unless offender.present?
        end  
      end
      puts "Totally #{counter} complaints cases couldn't find the linked offender SAR case."
    end

    private 

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

  end
end
