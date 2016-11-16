class Correspondence < ApplicationRecord

  acts_as_gov_uk_date :received_date

  validates :name, :category, :message, :received_date, :subject, presence: true
  validates :email, presence: true, on: :create, if: -> { postal_address.blank? }
  validates :email, format: { with: /\A.+@.+\z/ }, if: -> { email.present? }
  validates :postal_address, presence: true, on: :create, if: -> { email.blank? }
  validates :email, confirmation: { case_sensitive: false }
  validates :subject, length: { maximum: 80 }

  attr_accessor :email_confirmation
  jsonb_accessor :properties,
    escalation_deadline: :datetime,
    internal_deadline: :datetime,
    external_deadline: :datetime,
    trigger: [:boolean, default: false]

  belongs_to :user, required: false
  belongs_to :category, required: true

  before_create :set_deadlines
  after_update :assigned_state, if: :drafter_assigned?
  after_update :set_deadlines

  def triggerable?
    category.abbreviation == 'FOI' && !trigger?
  end

  def requires_approval?
    category.abbreviation == 'GQ' || trigger?
  end

  def self.search(term)
    where('lower(name) LIKE ?', "%#{term.downcase}%")
  end

  def drafter
    user
  end

  private

  def set_deadlines
    self.escalation_deadline = DeadlineCalculator.escalation_deadline(self) if triggerable?
    self.internal_deadline = DeadlineCalculator.internal_deadline(self) if requires_approval?
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
