require "csv"
require "json"

namespace :ico_appeal do
  namespace :relink do
    desc "Relink the ico appeal case to related FOI internal review case if it has or from input csv file."
    task :perform, [:file] => :environment do |_task, args|
      ico_appeal_foi_ids_map = {}
      if args[:file].present?
        raise "The file doesn't exist" unless File.file?(args[:file])

        puts "Read the id of FOI internal review case for a specific ico appeal case from csv"
        CSV.foreach(args[:file], headers: true) do |row|
          ico_appeal_id = row["ico_appeal_id"].to_i
          foi_type_case_id = row["foi_type_case_id"].to_i
          if is_valid_ids?(ico_appeal_id, foi_type_case_id)
            ico_appeal_foi_ids_map[ico_appeal_id] = foi_type_case_id
          end
        end
        puts ico_appeal_foi_ids_map
      end
      counter = 0
      ico_appeal_cases = Case::ICO::FOI.all
      ico_appeal_cases.each do |ico_appeal|
        puts "Checking ico appeal #{ico_appeal.number}"
        foi_ir_id = find_related_foi_ir_case_id(ico_appeal, ico_appeal_foi_ids_map)
        next if foi_ir_id.blank?

        foi_ir_case = Case::Base.find(foi_ir_id)
        existing_original_case_id = ico_appeal.original_case.id
        clear_up_old_related_link(ico_appeal.id, foi_ir_id)
        clear_up_old_links(ico_appeal, "original")
        create_new_case_link(ico_appeal, foi_ir_case.id, "original")
        if existing_original_case_id != foi_ir_id
          create_new_case_link(ico_appeal, existing_original_case_id, "related")
        end
        counter += 1
        puts "Updated ico appeal #{ico_appeal.number}'s original case to #{foi_ir_case.number}."
      end
      puts "Totally #{counter} ico appeal cases have been updated with new original case link."
    end

    desc "Check the linkage among the chain of ico_appeal -> foi standard -> foi internal review."
    task :check, [:file] => :environment do |_task, args|
      raise "Must specify the csv file for outputing the result " if args[:file].blank?

      counter = 0

      CSV.open(args[:file], "wb") do |csv|
        csv << %w[ico_appeal_id
                  ico_appeal_case_number
                  original_link_case_id
                  link_case_type
                  link_case_number
                  related_foi_ir_ids
                  related_foi_ir_numbers
                  related_foi_ir_types
                  foi_ir_case_ids_from_origin
                  foi_ir_case_numbers_from_origin
                  foi_ir_case_types_from_origin
                  foisar_ids_from_origin
                  foisar_numbers_from_origin
                  foisar_types_from_origin]
        counter = 0
        records = Case::ICO::Base.all
        records.each do |record|
          puts "Checking ico appeal #{record.number}"
          counter += 1
          related_ir_cases_from_origin = filter_related_cases(
            record.original_case,
            ["Case::FOI::ComplianceReview", "Case::FOI::TimelinessReview"],
          )
          related_ir_cases = filter_related_cases(
            record,
            ["Case::FOI::ComplianceReview", "Case::FOI::TimelinessReview"],
          )
          related_foisar_cases_from_origin = filter_related_cases(
            record.original_case,
            ["Case::FOI::Standard", "Case::SAR::Standard"],
          )
          csv << [record.id,
                  record.number,
                  record.original_case.present? ? record.original_case.id : "",
                  record.original_case.present? ? record.original_case.type : "",
                  record.original_case.present? ? record.original_case.number : "",
                  related_ir_cases.map(&:id).join("; "),
                  related_ir_cases.map(&:number).join(";"),
                  related_ir_cases.map(&:type).join("; "),
                  related_ir_cases_from_origin.map(&:id).join("; "),
                  related_ir_cases_from_origin.map(&:number).join(";"),
                  related_ir_cases_from_origin.map(&:type).join("; "),
                  related_foisar_cases_from_origin.map(&:id).join("; "),
                  related_foisar_cases_from_origin.map(&:number).join(";"),
                  related_foisar_cases_from_origin.map(&:type).join("; ")]
        end
      end
      puts "Totally #{counter} ico appeal cases."
    end

  private

    def is_valid_ids?(ico_appeal_id, foi_type_case_id)
      valid_ico_appeal = Case::ICO::Base.exists?(ico_appeal_id)
      valid_foi_type_case = Case::Base.exists?(foi_type_case_id)
      puts "#{ico_appeal_id} does not exist!" unless valid_ico_appeal
      puts "#{foi_type_case_id} does not exist!" unless valid_foi_type_case

      valid_ico_appeal && valid_foi_type_case
    end

    def find_related_foi_ir_case_id(ico_appeal, ico_appeal_foi_ids_map)
      if ico_appeal_foi_ids_map[ico_appeal.id].present?
        ico_appeal_foi_ids_map[ico_appeal.id]
      elsif ico_appeal.original_case.blank?
        puts "ico appeal(#{ico_appeal.id}) has no original case."
        elseif is_foi_ir_case?(ico_appeal.original_case.type)
        puts "ico appeal(#{ico_appeal.id}) has linked to a FOI internal review case(#{ico_appeal.original_case.id})."
      else
        check_related_foi_ir_cases(ico_appeal)
      end
    end

    def check_related_foi_ir_cases(ico_appeal)
      result = nil
      related_ir_cases = filter_related_cases(
        ico_appeal.original_case,
        ["Case::FOI::ComplianceReview", "Case::FOI::TimelinessReview"],
      )
      case related_ir_cases.count
      when 1
        result = related_ir_cases.first.id
      when 0
        puts "ico appeal(#{ico_appeal.id}) has no FOI internal review to be linked with."
      else
        puts "ico appeal(#{ico_appeal.id}) has 2 choices for FOI internal review [#{related_ir_cases.map(&:id).join(', ')}]"
      end
      result
    end

    def filter_related_cases(record, case_types)
      if record.present?
        related_ir_cases = []
        (record.related_cases || []).each do |related_case|
          related_ir_cases << related_case if case_types.include?(related_case.type)
        end
        related_ir_cases
      else
        []
      end
    end

    def is_foi_ir_case?(case_type)
      ["Case::FOI::ComplianceReview", "Case::FOI::TimelinessReview"].include?(case_type)
    end

    def clear_up_old_links(ico_appeal, link_type)
      case_linkage_records = LinkedCase.where(type: link_type, case_id: ico_appeal.id)
      case_linkage_records.each(&:destroy)
    end

    def clear_up_old_related_link(ico_appeal_id, foi_ir_id)
      case_linkage_records = LinkedCase.where(type: "related", case_id: ico_appeal_id, linked_case_id: foi_ir_id)
      case_linkage_records.each(&:destroy)
    end

    def create_new_case_link(ico_appeal, link_case_id, link_type)
      new_original_case_link = LinkedCase.new(case_id: ico_appeal.id, linked_case_id: link_case_id, type: link_type.to_sym)
      new_original_case_link.save!
    end
  end
end
