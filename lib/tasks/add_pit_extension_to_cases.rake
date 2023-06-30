require "csv"
require "json"

def get_records_having_extension_events
  case_ids = CaseTransition.where(event: %w[extend_for_pit remove_pit_extension])
  .distinct(:case_id)
  .pluck(:case_id)
  Case::Base.where(id: case_ids)
end

def check_record_extension_flag(record)
  calculated_flag = false
  num_extend_for_pit = 0
  num_remove_pit_extension = 0
  record.transitions.order(:id).each do |transaction|
    if transaction.event == "extend_for_pit"
      calculated_flag = true
      num_extend_for_pit += 1
    end
    if transaction.event == "remove_pit_extension"
      calculated_flag = false
      num_remove_pit_extension += 1
    end
  end
  { calculated_flag:,
    num_extend_for_pit:,
    num_remove_pit_extension: }
end

namespace :cases do
  namespace :pit_extension do
    desc "Add the pit extension flag if the case has been extended and the flag is missing"
    task :perform, [] => :environment do |_task, _|
      counter = 0
      records = get_records_having_extension_events
      records.each do |record|
        result = check_record_extension_flag(record)
        next unless result[:calculated_flag] != record.has_pit_extension?

        puts "Found case #{record.number} has no has_pit_extension"
        begin
          record.has_pit_extension = result[:calculated_flag]
          record.save!
          counter += 1
          puts "** Done case #{record.number} **"
        rescue StandardError => e
          puts "Failed to update the extension flag for case #{record.number} due to #{e.message}"
        end
      end
      puts "Totally #{counter}cases have been updated with has_pit_extension flag."
    end

    desc "Get the list of cases which has been extended but no pit-extension flag"
    task :check, [:file] => :environment do |_task, args|
      raise "Must specify the csv file for outputing the result " if args[:file].blank?

      CSV.open(args[:file], "wb") do |csv|
        csv << ["case_id",
                "case_number",
                "type",
                "has flag?",
                "number of extend_for_pit",
                "number of remove_pit_extension",
                "present_flag",
                "calculated_flag"]
        counter = 0
        records = get_records_having_extension_events
        records.each do |record|
          puts "Checking case #{record.number}"
          counter += 1
          result = check_record_extension_flag(record)
          csv << [record.id,
                  record.number,
                  record.type,
                  record.properties["has_pit_extension"].present?,
                  result[:num_extend_for_pit],
                  result[:num_remove_pit_extension],
                  record.has_pit_extension?,
                  result[:calculated_flag]]
        end
      end
      puts "Totally #{counter} extended FOI cases."
    end
  end
end
