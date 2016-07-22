class Correspondence < ApplicationRecord

  validates_presence_of :name, :email, :typus, :topic, :message, :email_confirmation
  validates_confirmation_of :email, case_sensitive: false

  attr_accessor :email_confirmation

end
