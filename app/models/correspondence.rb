class Correspondence < ApplicationRecord

  validates :name, :email, :category, :topic, :message, :email_confirmation, presence: true, on: :create
  validates :email, confirmation: { case_sensitive: false }

  attr_accessor :email_confirmation

  belongs_to :user, required: false

  after_update :assign, if: :assignation_made?

  def self.search(term)
    where('lower(name) LIKE ?', "%#{term.downcase}%")
  end

  def drafter
    self.user
  end

  private

  def assign
    self.state = "assigned"
  end

  def assignation_made?
    self.state == "submitted" && user.present?
  end

end
