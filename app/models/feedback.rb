class Feedback < ApplicationRecord

  validates :comment, :email, presence: true

  jsonb_accessor :content,
                 comment:     :text,
                 email:       :text,
                 user_agent:  :text,
                 referer:     :text
end
