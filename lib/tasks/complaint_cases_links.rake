require 'csv'

namespace :complaints do
  namespace :links do

    desc "Check whether the offender sar being referred to in Complaint case exists in DB or not."
    task :check, [:file] => :environment do |_task, args|
      raise "Must specify the csv file containing the list of complaint cases" if args[:file].blank?    
      raise "The file doesn't exist" if !File.file?(args[:file])
      result_file = "#{args[:file].delete("csv")}_checking_result.csv"
      counter = 1
      CSV.open(result_file, "wb") do |csv|
        csv << ["ReqNo", "DPARefNo", "Exist?", ]
        CSV.foreach(args[:file], headers: true) do |row|
          puts "Checking #{row['DPARefNo']}"
          offender = Case::SAR::Offender.find_by_number("MIG#{row['DPARefNo']}")
          csv << [row["ReqNo"], row["DPARefNo"], (offender.present? ? "Y" : "N")]
          counter += 1 unless offender.present?
        end  
      end
      puts "Totally #{counter} complaints cases couldn't find the linked offender SAR case."
    end
  end
end
