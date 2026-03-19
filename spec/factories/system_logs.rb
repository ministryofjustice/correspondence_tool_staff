# == Schema Information
#
# Table name: system_logs
#
#  id            :bigint           not null, primary key
#  type          :string           not null
#  status        :string           default("pending")
#  reference_id  :string
#  action        :string
#  source        :string
#  metadata      :jsonb            default({})
#  error_message :text
#  duration_ms   :float
#  completed_at  :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

FactoryBot.define do
  factory :system_log do
    type { "SystemLog" }
    status { "pending" }
    source { "TestSource" }
    action { "test_action" }
    reference_id { SecureRandom.uuid }
    metadata { {} }

    trait :successful do
      status { "success" }
      completed_at { Time.current }
      duration_ms { 123.45 }
    end

    trait :failed do
      status { "failed" }
      error_message { "Something went wrong" }
      duration_ms { 50.0 }
    end

    factory :email_log, class: "EmailLog" do
      type { "EmailLog" }
      source { "ActionNotificationsMailer" }
      action { "new_assignment" }
      reference_id { "<#{SecureRandom.uuid}@test.mail>" }
      metadata do
        {
          "to" => Faker::Internet.email,
          "from" => "noreply@example.com",
          "subject" => "Test email subject",
        }
      end
    end
  end
end
