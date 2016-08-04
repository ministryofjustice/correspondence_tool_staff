class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable and :omniauthable
  devise :database_authenticatable, :timeoutable,
    :recoverable, :trackable, :validatable

  has_many :correspondence

end
