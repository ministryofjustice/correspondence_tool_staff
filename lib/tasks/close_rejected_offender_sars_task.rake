namespace :close_rejected_offender_sars do
  desc "Close rejected offender sars that were received over the deadline"
  task update_statuses: :environment do
    CaseSAROffender.scope: "late".each do |rejected_offender_sar|
      rejected_offender_sar.update!(current_state: "closed", date_responded: Time.zone.today)
      rejected_offender_sar.save!
    end
  end
end
