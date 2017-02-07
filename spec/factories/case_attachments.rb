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
    association :case
    url {
      "https://correspondence-staff-uploads.s3.amazonaws.com/" +
        "#{SecureRandom.hex(32)}/" +
        "responses/#{Faker::Internet.slug}.pdf"
    }

    factory :correspondence_response do
      type 'response'
    end

  end
end
