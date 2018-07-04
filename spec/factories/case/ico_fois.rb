FactoryBot.define do

  sequence(:ico_foi_reference_number) { |n| "ICOFOIREFNUM%03d" % [n] }

  factory :ico_foi_case, class: Case::ICO::FOI do
    transient do
      identifier      "new ICO FOI case"
      managing_team   { find_or_create :team_dacu }
    end

    current_state          'unassigned'
    sequence(:subject)     { |n| "#{identifier} subject #{n}" }
    sequence(:message)     { |n| "#{identifier} message #{n}" }
    ico_reference_number   { generate :ico_foi_reference_number }
    received_date          { 0.business_days.from_now }
    external_deadline      { 20.business_days.from_now.to_date }
    uploaded_request_files { ["#{Faker::Internet.slug}.pdf"] }
    uploading_user         { find_or_create :manager }
  end
end

