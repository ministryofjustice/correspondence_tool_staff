class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable and :omniauthable
  devise :database_authenticatable, :timeoutable,
    :recoverable, :trackable, :validatable

  has_many :cases, through: :assignments
  has_many :assignments, foreign_key: 'assignee_id'

  ROLES = %w[assigner drafter approver].freeze

  include Roles

end
