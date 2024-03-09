namespace :close_rejected_offender_sars do
  desc "Close rejected offender SARs that were received over the deadline"
  task update_statuses: :environment do
      Case::SAR::Offender.late.find_each do |rejected_offender_sar|
      rejected_offender_sar.update!(current_state: "closed", date_responded: Time.zone.today)
    end
  end
end
