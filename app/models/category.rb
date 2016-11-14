class Category < ApplicationRecord

  validates :name, :abbreviation, :escalation_time_limit, :internal_time_limit,
    :external_time_limit, presence: true, on: :create

  has_many :correspondence

end
