class Correspondence < ApplicationRecord

  validates :name, :email, :category, :topic, :message, :email_confirmation,
    presence: true, on: :create

  validates :email, confirmation: { case_sensitive: false }

  attr_accessor :email_confirmation

  belongs_to :user, required: false
  belongs_to :category, required: true

  after_update :assigned_state, if: :drafter_assigned?

  def self.search(term)
    where('lower(name) LIKE ?', "%#{term.downcase}%")
  end

  def drafter
    user
  end

  def internal_deadline
    category.internal_time_limit
  end

  private

  def assigned_state
    self.state = "assigned"
    save!
  end

  def drafter_assigned?
    state == "submitted" && user.present?
  end

end
