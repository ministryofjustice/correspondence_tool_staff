class LinkedCase < ApplicationRecord
  belongs_to :case, class_name: 'Case::Base'
  belongs_to :linked_case, class_name: 'Case::Base'

  after_create :create_reverse_link

  def create_reverse_link
    self.class.skip_callback(:create, :after, :create_reverse_link)
    self.class.create(case_id: linked_case_id, linked_case_id: self.case_id)
  rescue ActiveRecord::RecordNotUnique
    nil
  ensure
    self.class.set_callback(:create, :after, :create_reverse_link)
  end
end
