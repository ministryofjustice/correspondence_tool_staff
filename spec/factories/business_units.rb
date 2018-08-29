FactoryBot.define do


  factory :business_unit do
    transient do
      lead                 { create :deputy_director }
      correspondence_type_ids { [] }
    end

    sequence(:name)     { |n| "Business Unit #{n}" }
    email               { name.downcase.gsub(/\W/, '_') + '@localhost' }
    role                { 'responder' }
    correspondence_types { [find_or_create(:foi_correspondence_type),
                            find_or_create(:sar_correspondence_type),
                            find_or_create(:ico_correspondence_type),] }
    directorate         { find_or_create :directorate }
    properties          { [find_or_create(:team_property, :area)] }

    after :create do |bu, evaluator|
      bu.properties << evaluator.lead
    end

    before :create do |bu, evaluator|
      if evaluator.correspondence_type_ids.present?
        bu.correspondence_type_ids = evaluator.correspondence_type_ids
      end
    end
  end


  factory :managing_team, parent: :business_unit do
    transient do
      managers { [] }
    end

    sequence(:name) { |n| "Managing Team #{n}" }
    directorate { find_or_create :directorate, name: 'Management Directorate' }
    role { 'manager' }

    after(:create) do |team, evaluator|
      if evaluator.managers.present?
        team.managers << evaluator.managers
      elsif team.managers.empty?
        team.managers << create(:user)
      end
    end
  end

  factory :responding_team, parent: :business_unit do
    sequence(:name) { |n| "Responding Team #{n}" }
    responders { [create(:user)] }
  end

  factory :approving_team, parent: :business_unit do

    sequence(:name) { |n| "Approving Team #{n}" }
    role { 'approver' }
    approvers { [create(:user)] }
  end

  factory :team_disclosure_bmt, aliases: [:team_dacu], parent: :managing_team do
    name { 'Disclosure BMT' }
    email { 'dacu@localhost' }
    code { Settings.foi_cases.default_managing_team }
    directorate { find_or_create :dacu_directorate }
  end

  factory :team_disclosure, aliases: [:team_dacu_disclosure], parent: :approving_team do
    name { 'Disclosure' }
    email { 'dacu.disclosure@localhost' }
    code { Settings.foi_cases.default_clearance_team }
    approvers { [] }

    after :create do |bu, _evaluator|
      if bu.approvers.empty?
        create(:disclosure_specialist, approving_team: bu)
      end
    end
  end

  factory :team_press_office, parent: :approving_team do
    name { 'Press Office' }
    email { 'press.office@localhost' }
    code { Settings.press_office_team_code }
    directorate { find_or_create :press_office_directorate }
  end

  factory :team_private_office, parent: :approving_team do
    name { 'Private Office' }
    email { 'private.office@localhost' }
    code { Settings.private_office_team_code }
    directorate { find_or_create :press_office_directorate }
  end

  trait :deactivated do
    deleted_at { Time.now }
  end
end
