namespace :email do
  desc "Get email statuses from Notify and update record"
  task update_statuses: :environment do
    DataRequestEmail.delivering.each do |email|
      email.update_status_with_delay(delay: 0.seconds)
    end
  end
end
