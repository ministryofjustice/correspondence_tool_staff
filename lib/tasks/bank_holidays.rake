require Rails.root.join('db/seeders/bank_holidays_seeder')

namespace :bank_holidays do
  desc "Seed bank holidays from JSON file"
  task seed: :environment do
    BankHolidays::Seeder.seed_from_file
  end
end
