FactoryBot.define do

  sequence(:ico_sar_reference_number) { |n| "ICOSARREFNUM%03d" % [n] }

  factory :ico_sar_case, class: Case::ICO::SAR do
    transient do
      identifier    "new ICO SAR case"
      managing_team { find_or_create :team_dacu }
    end

    current_state          'unassigned'
    sequence(:subject)     { |n| "#{identifier} subject #{n}" }
    ico_reference_number   { generate :ico_sar_reference_number }
    received_date          { 0.business_days.from_now }
    external_deadline      { 20.business_days.from_now.to_date }
    uploaded_request_files { ["#{Faker::Internet.slug}.pdf"] }
    uploading_user         { find_or_create :manager }
  end
end
