# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#  parent_id  :integer
#  role       :string
#  code       :string
#  deleted_at :datetime
#

FactoryBot.define do

  trait :empty do
    approvers  { [] }
    managers   { [] }
    responders { [] }
    users      { [] }
  end

  factory :business_unit do
    initialize_with do
      BusinessUnit.find_or_create_by(name: name, email: email)
    end

    transient do
      lead                 { create :deputy_director }
      correspondence_type_ids { [] }
    end

    sequence(:name)     { |n| "Business Unit #{n}" }
    email               { name.downcase.gsub(/\W/, '_') + '@localhost' }
    role                { 'responder' }
    correspondence_types { [
                             find_or_create(:foi_correspondence_type),
                             find_or_create(:sar_correspondence_type),
                             find_or_create(:ico_correspondence_type),
                             find_or_create(:sar_internal_review_correspondence_type),
                           ] }
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
    sequence(:name) { |n| "Managing Team #{n}" }
    directorate { find_or_create :directorate, name: 'Management Directorate' }
    role { 'manager' }
    managers { [create(:manager, :orphan)] }

    after(:create) do |team, evaluator|
    end
  end

  factory :team_for_admin_users, parent: :business_unit do
    sequence(:name) { |n| "Team-admin Team #{n}" }
    directorate { find_or_create :directorate, name: 'Management Directorate' }
    role { 'team_admin' }
    team_admins { [create(:responder, :orphan)] }

    after(:create) do |team, evaluator|
    end
  end

  factory :responding_team, parent: :business_unit do
    sequence(:name) { |n| "Responding Team #{n}" }
    responders { [create(:responder, :orphan)] }

    after(:create) do |bu, _evaluator|
      bu.correspondence_types << find_or_create(:overturned_sar_correspondence_type)
      bu.correspondence_types << find_or_create(:overturned_foi_correspondence_type)
    end
  end

  factory :foi_responding_team, parent: :business_unit do
    directorate { find_or_create :responder_directorate }
    name { "FOI Responding Team" }
    responders { [find_or_create(:foi_responder, :orphan)] }

    after(:create) do |bu, _evaluator|
      bu.correspondence_types << find_or_create(:overturned_foi_correspondence_type)
    end
  end

  factory :sar_responding_team, parent: :business_unit do
    directorate { find_or_create :responder_directorate }
    name { "SAR Responding Team" }
    responders { [find_or_create(:sar_responder, :orphan)] }

    after(:create) do |bu, _evaluator|
      bu.correspondence_types << find_or_create(:overturned_sar_correspondence_type)
    end
  end

  factory :approving_team, parent: :business_unit do
    sequence(:name) { |n| "Approving Team #{n}" }
    role { 'approver' }
    approvers { [create(:approver, :orphan)] }
  end

  factory :team_disclosure_bmt, aliases: [:team_dacu], parent: :managing_team do
    name { 'Disclosure BMT' }
    email { 'dacu@localhost' }
    code { Settings.foi_cases.default_managing_team }
    directorate { find_or_create :dacu_directorate }
    managers { [find_or_create(:disclosure_bmt_user, :orphan)] }
  end

  factory :team_branston, parent: :business_unit do
    name { 'Branston Registry' }
    email { 'branston@localhost' }
    code { 'BRANSTON' }
    directorate { find_or_create :dacu_directorate }
    responders { [find_or_create(:branston_user, :orphan)] }

    after(:create) do |bu, _evaluator|
      bu.correspondence_types = []
      bu.correspondence_types << find_or_create(:offender_sar_correspondence_type)
      bu.correspondence_types << find_or_create(:offender_sar_complaint_correspondence_type)
      bu.save!
    end
  end

  factory :team_disclosure, aliases: [:team_dacu_disclosure], parent: :approving_team do
    name { 'Disclosure' }
    email { 'dacu.disclosure@localhost' }
    code { Settings.foi_cases.default_clearance_team }
    directorate { find_or_create :dacu_directorate }
    approvers { [find_or_create(:disclosure_specialist, :orphan)] }

    after :create do |bu, _evaluator|
      if bu.approvers.empty?
        find_or_create(:disclosure_specialist, approving_team: bu)
      end
    end
  end

  factory :team_press_office, aliases: [:press_office], parent: :approving_team do
    name        { 'Press Office' }
    email       { 'press.office@localhost' }
    code        { Settings.press_office_team_code }
    directorate { find_or_create :press_office_directorate }
    approvers   { [find_or_create(:press_officer, :orphan)] }
  end

  factory :team_private_office, parent: :approving_team do
    name        { 'Private Office' }
    email       { 'private.office@localhost' }
    code        { Settings.private_office_team_code }
    directorate { find_or_create :press_office_directorate }
    approvers   { [find_or_create(:private_officer, :orphan)] }
  end

  trait :deactivated do
    deleted_at { Time.zone.now }
  end
end
