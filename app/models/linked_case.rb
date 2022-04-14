# == Schema Information
#
# Table name: linked_cases
#
#  id             :integer          not null, primary key
#  case_id        :integer          not null
#  linked_case_id :integer          not null
#  type           :string           default("related")
#

class LinkedCase < ApplicationRecord
  self.inheritance_column = :_unused

  attr_accessor :linked_case_number

  belongs_to :case, class_name: 'Case::Base',
             inverse_of: :linked_cases

  belongs_to :linked_case, class_name: 'Case::Base'

  enum type: {
         related: 'related',
         original: 'original',
         original_appeal: 'original_appeal'
       }

  scope :related_and_appeal, -> {  related.or(original_appeal).order(:type, :id) }

  before_validation :find_linked_case_by_number
  after_create :create_reverse_link
  after_destroy :destroy_reverse_link

  validates :linked_case_number,
            presence: true,
            if: -> { linked_case_id.nil? }

  validates_with ::CaseLinkTypeValidator,
                 if: -> { self.case_id.present? &&
                          (self.linked_case_id.present? ||
                           self.linked_case_number.present?) }
  validate :validate_case_not_linked_back_to_itself,
           if: -> { self.case_id.present? }

  private

  def find_linked_case_by_number
    if linked_case_number.present?
      self.linked_case = Case::Base.find_by(number: linked_case_number)
      if self.linked_case.nil?
        self.errors.add(:linked_case_number, :missing)
      end
    end
  end

  def validate_case_not_linked_back_to_itself
    if linked_case_number.present?
      if self.case.number == linked_case_number
        errors.add(:linked_case_number, :references_self)
      end
    else
      if self.case_id == linked_case_id
        errors.add(:linked_case, :references_self)
      end
    end
  end

  def create_reverse_link
    self.class.skip_callback(:create, :after, :create_reverse_link)
    self.class.create!(case_id: linked_case_id, linked_case_id: self.case_id)
  rescue ActiveRecord::RecordNotUnique
    nil
  ensure
    self.class.set_callback(:create, :after, :create_reverse_link)
  end

  def destroy_reverse_link
    self.class.skip_callback(:destroy, :after, :destroy_reverse_link)
    reverse_link = self.class.find_by(case_id: linked_case_id,
                                      linked_case_id: self.case_id)
    reverse_link&.destroy
  ensure
    self.class.set_callback(:destroy, :after, :destroy_reverse_link)
  end
end
