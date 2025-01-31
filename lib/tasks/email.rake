namespace :email do
  desc "Get email statuses from Notify and update record"
  task update_statuses: :environment do
    DataRequestEmail.delivering.each do |email|
      email.update_status_with_delay(delay: 0.seconds)
    end
  end

  desc "Send daily data request chase emails"
  task send_data_request_chase_emails: :environment do
    DataRequestChaseService.call
  end
end
