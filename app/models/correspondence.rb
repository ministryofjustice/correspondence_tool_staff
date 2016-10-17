class Correspondence < ApplicationRecord

  acts_as_gov_uk_date :received_date

  validates :name, :category, :message, :received_date, presence: true, on: :create
  validates :email, presence: true, on: :create, if: -> { postal_address.nil? }
  validates :email, format: { with: /\A.+@.+\z/ }, if: -> { email.present? }
  validates :postal_address, presence: true, on: :create, if: -> { email.nil? }
  validates :email, confirmation: { case_sensitive: false }

  attr_accessor :email_confirmation

  belongs_to :user, required: false
  belongs_to :category, required: true

  before_create :set_deadlines
  after_update :assigned_state, if: :drafter_assigned?

  def self.search(term)
    where('lower(name) LIKE ?', "%#{term.downcase}%")
  end

  def drafter
    user
  end

  private

  def set_deadlines
    self.internal_deadline = DeadlineCalculator.internal_deadline(self)
    self.external_deadline = DeadlineCalculator.external_deadline(self)
  end

  def assigned_state
    self.state = "assigned"
    save!
  end

  def drafter_assigned?
    state == "submitted" && user.present?
  end

end
