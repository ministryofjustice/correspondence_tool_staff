# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  roles                  :string
#  full_name              :string
#

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :recoverable, :confirmable, :lockable and :omniauthable

  devise :database_authenticatable, :timeoutable,
    :trackable, :validatable

  has_many :cases, through: :assignments
  has_many :assignments, foreign_key: 'assignee_id'

  validates :full_name, presence: true

  ROLES = %w[assigner drafter approver].freeze

  include Roles

end
