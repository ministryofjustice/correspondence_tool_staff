# == Schema Information
#
# Table name: category_references
#
#  id            :bigint           not null, primary key
#  category      :string
#  code          :string
#  value         :string
#  display_order :integer
#  deactivated   :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class CategoryReference < ApplicationRecord
  has_many :contacts, foreign_key: :contact_type, inverse_of: :contact_type

  def self.list_by_category(category)
    where(category:).order(:display_order)
  end
end
