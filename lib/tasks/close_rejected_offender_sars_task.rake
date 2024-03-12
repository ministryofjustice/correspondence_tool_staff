namespace :close_rejected_offender_sars do
  desc "Close rejected offender SARs that were received over the deadline"
  task update_statuses: :environment do
    Case::SAR::Offender.late.where(current_state: "rejected").each do |rejected_offender_sar|
      close_rejected_offender_sars_task("service CaseClosureService start #{rejected_offender_sar.id}")
    end
  end
end
