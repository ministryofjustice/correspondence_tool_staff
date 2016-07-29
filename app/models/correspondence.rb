class Correspondence < ApplicationRecord

  validates :name, :email, :category, :topic, :message, :email_confirmation, presence: true
  validates :email, confirmation: { case_sensitive: false }

  attr_accessor :email_confirmation

  
  def self.search(term)
    where('lower(name) LIKE ?', "%#{term.downcase}%")
  end

end
