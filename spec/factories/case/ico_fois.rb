FactoryBot.define do

  factory :ico_foi_case, class: Case::ICO::FOI do
    transient do
      creation_time   { 4.business_days.ago }
      identifier      "new FOI case"
      managing_team   { find_or_create :team_dacu }
    end

    current_state               'unassigned'
    sequence(:name)             { |n| "#{identifier} name #{n}" }
    sequence(:subject)          { |n| "ICO FOI Subject #{n}" }
    received_date               { Time.zone.today.to_s }
    created_at                  { creation_time }

  end
end

