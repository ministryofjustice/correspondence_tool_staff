class Case < ApplicationRecord

  acts_as_gov_uk_date :received_date

  scope :by_deadline, lambda {
    order("(properties ->> 'external_deadline')::timestamp with time zone ASC, id")
  }

  validates :name, :category, :message, :received_date, :subject, presence: true
  validates :email, presence: true, on: :create, if: -> { postal_address.blank? }
  validates :email, format: { with: /\A.+@.+\z/ }, if: -> { email.present? }
  validates :postal_address, presence: true, on: :create, if: -> { email.blank? }
  validates :subject, length: { maximum: 80 }

  jsonb_accessor :properties,
    escalation_deadline: :datetime,
    internal_deadline: :datetime,
    external_deadline: :datetime,
    trigger: [:boolean, default: false]

  has_many :assignees, through: :assignments
  belongs_to :category, required: true
  has_many :assignments

  before_create :set_deadlines
  after_update :set_deadlines

  def drafter
    assignees.select(&:drafter?).first
  end

  def triggerable?
    category.abbreviation == 'FOI' && !trigger?
  end

  def requires_approval?
    category.abbreviation == 'GQ' || trigger?
  end

  def self.search(term)
    where('lower(name) LIKE ?', "%#{term.downcase}%")
  end

  private

  def set_deadlines
    self.escalation_deadline = DeadlineCalculator.escalation_deadline(self) if triggerable?
    self.internal_deadline = DeadlineCalculator.internal_deadline(self) if requires_approval?
    self.external_deadline = DeadlineCalculator.external_deadline(self)
  end

end
