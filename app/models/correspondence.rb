class Correspondence < ApplicationRecord

  validates :name, :email, :category, :topic, :message, :email_confirmation, presence: true, on: :create
  validates :email, confirmation: { case_sensitive: false }

  attr_accessor :email_confirmation

  belongs_to :user, required: false

  def self.search(term)
    where('lower(name) LIKE ?', "%#{term.downcase}%")
  end

  def drafter
    self.user
  end

end
