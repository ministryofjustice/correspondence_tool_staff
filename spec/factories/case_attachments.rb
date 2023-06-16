# == Schema Information
#
# Table name: case_attachments
#
#  id           :integer          not null, primary key
#  case_id      :integer
#  type         :enum
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  key          :string
#  preview_key  :string
#  upload_group :string
#  user_id      :integer
#  state        :string           default("unprocessed"), not null
#

FactoryBot.define do
  factory :case_attachment do
    association :case, strategy: :build
    # TODO: The random hex number below isn't strictly true, we should have a
    #       hash of the case's ID ... except the default factory here doesn't
    #       have a case with an ID since we use strategy: :build. The reason
    #       for that is that we were getting errors in tests when using the
    #       default strategy of :create, so we need to fix that to fix the hex
    #       number we generate here.
    key { "#{SecureRandom.hex(16)}/responses/#{Faker::Internet.slug}.pdf" }
    preview_key { "#{SecureRandom.hex(16)}/response_previews/#{Faker::Internet.slug}.pdf" }
    upload_group { Time.zone.now.strftime("%Y%m%d%H%M%S") }
  end

  factory :correspondence_response, parent: :case_attachment do
    type { "response" }

    trait :without_preview_key do
      preview_key { nil }
    end
  end

  factory :case_response, parent: :correspondence_response do
    # Whatever was I thinking calling it :correspondence_response? Why didn't
    # you stop me Eddie?!?!

    trait :jpg do
      key { "#{SecureRandom.hex(16)}/responses/#{Faker::Internet.slug}.jpg" }
    end
  end

  factory :commissioning_document_attachment, parent: :case_attachment do
    type { "commissioning_document" }
  end

  factory :case_postal_request, parent: :case_attachment do
    type { "response" }
    key do
      "#{SecureRandom.hex(16)}/requests/" \
      "#{upload_group}/#{Faker::Internet.slug}.pdf"
    end
    preview_key do
      "#{SecureRandom.hex(16)}/request_previews/" \
      "#{upload_group}/#{Faker::Internet.slug}.pdf"
    end
  end

  factory :case_ico_decision, parent: :case_attachment do
    type { "ico_decision" }
    key do
      "#{SecureRandom.hex(16)}/ico_decision/" \
      "#{upload_group}/#{Faker::Internet.slug}.pdf"
    end
    preview_key do
      "#{SecureRandom.hex(16)}/ico_decision_previews/" \
      "#{upload_group}/#{Faker::Internet.slug}.pdf"
    end
  end
end
