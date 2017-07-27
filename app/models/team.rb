# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#

class Team < ApplicationRecord
  validates :name, uniqueness: true

  has_many :user_roles, class_name: 'TeamsUsersRole'
  has_many :users, through: :user_roles

  scope :with_user, ->(user) {
    includes(:user_roles)
      .where(teams_users_roles: { user_id: user.id })
  }
end
