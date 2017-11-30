# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#  parent_id  :integer
#  role       :string
#  code       :string
#  deleted_at :datetime
#

class Directorate < Team
  validates :parent_id, presence: true

  belongs_to :business_group, foreign_key: 'parent_id'
  has_many :business_units, foreign_key: 'parent_id'

  def child_type
    "business units"
  end
end
