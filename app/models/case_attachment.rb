# == Schema Information
#
# Table name: case_attachments
#
#  id         :integer          not null, primary key
#  case_id    :integer
#  type       :enum
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CaseAttachment < ActiveRecord::Base
  self.inheritance_column = :_type_not_used
  belongs_to :case

  validates :type, presence: true
end
