# frozen_string_literal: true

class UpdateRejectedReasonsData < ActiveRecord::DataMigration
  def up
    cases = Case::Base.offender_sar.where("properties -> 'rejected_reasons' @> ?", %w[cctv_bwcv].to_json)

    cases.find_each do |offender_sar_case|
      reasons = offender_sar_case.properties["rejected_reasons"].map do |reason|
        reason == "cctv_bwcv" ? "cctv_bwcf" : reason
      end

      offender_sar_case.properties.merge!("rejected_reasons" => reasons)
      offender_sar_case.save!
    end
  end
end
