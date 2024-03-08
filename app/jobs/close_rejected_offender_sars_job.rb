class CloseRejectedOffenderSarsJob < ApplicationJob
  queue_as :default

  def perform
    offender_sars_to_close.each do |offender_sar|
      offender_sar.update!(current_state: "closed", date_responded: Time.zone.today)
      offender_sar.save!
    end
  end

private

  def offender_sars_to_close
    _close_offender_sars = Case::SAR::Offender.where(current_state: "rejected")
                                             .where("received_date <= ?", 31.days.ago)
  end
end
