# == Schema Information
#
# Table name: categories
#
#  id                    :integer          not null, primary key
#  name                  :string
#  abbreviation          :string
#  internal_time_limit   :integer
#  external_time_limit   :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  escalation_time_limit :integer
#

class Category < ApplicationRecord

  validates :name, :abbreviation, :escalation_time_limit, :internal_time_limit,
    :external_time_limit, presence: true, on: :create

  has_many :cases

  def self.foi
    find_by!(abbreviation: 'FOI')
  end

  def self.gq
    find_by!(abbreviation: 'GQ')
  end
end
