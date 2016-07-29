class Correspondence < ApplicationRecord

  validates :name, :email, :category, :topic, :message, :email_confirmation, presence: true
  validates :email, confirmation: { case_sensitive: false }

  attr_accessor :email_confirmation

end
