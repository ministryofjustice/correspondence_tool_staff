require "digest"

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
  validates :hash_value, presence: true

  before_save :update_hash_value

private

  def compute_data_hash
    Digest::SHA256.hexdigest(data.to_json)
  end

  def data_changed?
    compute_data_hash != hash_value
  end

  def update_hash_value
    self.hash_value = compute_data_hash
  end
end
