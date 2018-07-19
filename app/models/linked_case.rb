class LinkedCase < ApplicationRecord
  self.inheritance_column = :_unused

  belongs_to :case, class_name: 'Case::Base',
             inverse_of: :linked_cases

  belongs_to :linked_case, class_name: 'Case::Base'

  enum type: {
         related: 'related',
         original: 'original',
       }
  after_create :create_reverse_link
  after_destroy :destroy_reverse_link

  validates_with ::CaseLinkTypeValidator, if: ->(link) { not link.case.nil? }
  validate :validate_case_not_linked_back_to_itself

  private

  def validate_case_not_linked_back_to_itself
    if self.case_id == self.linked_case_id
      errors.add(:linked_case, :references_self)
    end
  end

  def create_reverse_link
    self.class.skip_callback(:create, :after, :create_reverse_link)
    self.class.create(case_id: linked_case_id, linked_case_id: self.case_id)
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
