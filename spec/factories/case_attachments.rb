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

FactoryGirl.define do
  factory :case_attachment do
    association :case, strategy: :build
    url {
      CASE_UPLOADS_S3_BUCKET.url +
        "/#{SecureRandom.hex(32)}/" +
        "responses/#{Faker::Internet.slug}.pdf"
    }
  end

  factory :correspondence_response, parent: :case_attachment do
    type 'response'
  end
  factory :case_response, parent: :correspondence_response do
    # Whatever was I thinking calling it :correspondence_response? Why didn't
    # you stop me Eddie?!?!
  end
end
