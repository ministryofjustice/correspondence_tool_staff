# == Schema Information
#
# Table name: feedback
#
#  id         :integer          not null, primary key
#  content    :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Feedback < ApplicationRecord
  validates :comment, :email, presence: true

  jsonb_accessor :content,
                 comment: :text,
                 email: :text,
                 user_agent: :text,
                 referer: :text

  scope :by_year, ->(year) { where("extract(year from created_at) = ?", year) }
end
