# == Schema Information
#
# Table name: bank_holidays
#
#  id               :integer          not null, primary key
#  data             :json             not null, default({})
#  hash_value       :hash             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null


class BankHolidays < ApplicationRecord
  validates :data, presence: true
end
