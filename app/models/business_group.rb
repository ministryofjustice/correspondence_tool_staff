# == Schema Information
#
# Table name: teams
#
#  id               :integer          not null, primary key
#  name             :string           not null
#  email            :citext
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  type             :string
#  parent_id        :integer
#  role             :string
#  code             :string
#  deleted_at       :datetime
#  moved_to_unit_id :integer
#

class BusinessGroup < Team
  validates :parent_id, absence: true

  has_many :directorates, foreign_key: "parent_id"

  has_many :business_units, through: :directorates

  def child_type
    "directorates"
  end
end
