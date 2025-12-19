# Only SAR/Offender SAR cases have 'stop the clock' functionality.
# See CaseClosureService for the ALL case type close process.
class CaseAutoCloseService
  def self.call(dryrun: true)
    Rails.logger.info("Paused/Stopped SAR Cases due for auto-close:") if dryrun

    resultset = Case::Base.in_stop_the_clock_state.select { |c| c.try(:prolonged_stop?) }

    if dryrun
      Rails.logger.info("Processing: #{resultset.size} paused/stopped cases")
    end

    resultset.each do |kase|
      if dryrun
        num_days = (Time.zone.today - kase.stopped_at).to_i
        Rails.logger.info("Case ID: #{kase.id} --- Paused/Stopped at: #{kase.stopped_at} for #{num_days} days")
      else
        ActiveRecord::Base.transaction do
          kase.state_machine.auto_close!(
            acting_user: User.system_admin,
            acting_team: kase.managing_team,
            message: "Auto-closed by system due to pause exceeding #{Settings.auto_close_stopped_threshold} days.",
          )

          service = RetentionSchedules::AddScheduleService.new(kase:, user: User.system_admin)
          service.call

          Rails.logger.info("Case ID: #{kase.id} --- Auto Closed successfully --- Retention schedule: #{service.result}")
        rescue StandardError => e
          Rails.logger.error("Error auto-closing Case ID: #{kase.id} --- #{e.message}")
        end
      end
    end
  end
end
