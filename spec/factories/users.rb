# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  full_name              :string           not null
#  deleted_at             :datetime
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#

def email_from_name(name)
  email_name = name.tr(" ", ".").gsub(/\.{2,}/, ".")
  "correspondence-staff-dev+#{email_name}@digital.justice.gov.uk"
end

FactoryBot.define do
  sequence(:manager_name)                     { |n| "Ms Manager #{n}" }
  sequence(:responder_name)                   { |n| "Mr Responder #{n}" }
  sequence(:approver_name)                    { |n| "Ms Approver #{n}" }
  sequence(:disclosure_specialist_name)       { |n| "Disclosure Specialist #{n}" }
  sequence(:disclosure_bmt_user_name)         { |n| "Disclosure BMT #{n}" }
  sequence(:press_officer_name)               { |n| "Press Officer #{n}" }
  sequence(:private_officer_name)             { |n| "Private Officer #{n}" }
  sequence(:approver_responder_name)          { |n| "Ms Approver-Responder #{n}" }
  sequence(:approver_responder_manager_name)  { |n| "Mgr Approver-Responder #{n}" }

  factory :user do
    initialize_with { User.find_or_create_by(email:) }

    transient do
      identifier { "user" }
    end

    # NB: when using either 'find' or 'find_or_create' strategies, the existing
    #     user that is found will have it's password set to 'nil'.
    ENV["TESTSPEC_LOGIN_PASSWORD"] = SecureRandom.random_number(36**13).to_s(36)
    password { ENV["TESTSPEC_LOGIN_PASSWORD"] }
    sequence(:full_name) { |n| "#{identifier} #{n}" }
    email { Faker::Internet.email(name: full_name) }

    trait :dev do
      email { email_from_name(full_name) }
    end

    trait :findable do
      full_name { identifier }
      email { email_from_name(identifier) }
    end

    factory :manager, parent: :user do
      transient do
        identifier { "managing user" }
      end

      full_name      { generate(:manager_name) }
      managing_teams { [create(:managing_team, :empty)] }
    end

    factory :manager_approver do
      transient do
        identifier { "managing-approving user" }
      end

      full_name      { generate(:manager_name) }
      managing_teams { [create(:managing_team)] }
      approving_team { create(:team_disclosure) }
    end

    factory :disclosure_bmt_user, parent: :manager do
      transient do
        identifier { "disclosure-bmt managing user" }
      end

      full_name      { identifier }
      email          { email_from_name(full_name) }
      managing_teams { [find_or_create(:team_dacu, :empty)] }
    end

    factory :branston_user, parent: :user do
      transient do
        identifier { "branston registry responding user" }
      end

      full_name      { identifier }
      email          { email_from_name(full_name) }
      managing_teams { [find_or_create(:team_branston, :empty)] }
    end

    factory :sscl_user, parent: :user do
      transient do
        identifier { "sscl responding user" }
      end

      full_name      { identifier }
      email          { email_from_name(full_name) }
      responding_teams { [find_or_create(:team_sscl, :empty)] }
    end

    factory :team_admin, parent: :user do
      transient do
        identifier { "team-admin user " }
      end

      full_name      { identifier }
      email          { email_from_name(full_name) }
      team_admin_teams { [find_or_create(:team_for_admin_users, :empty)] }
    end

    trait :orphan do
      approving_team { nil }
      managing_teams { [] }
      responding_teams { [] }
      teams { [] }
    end

    factory :responder do
      transient do
        identifier { "responding user" }
      end

      full_name { generate(:responder_name) }
      responding_teams { [find_or_create(:responding_team)] }
    end

    factory :responder_and_team_admin do
      transient do
        identifier { "team_admin and responder user" }
      end

      full_name { generate(:responder_name) }
      responding_teams { [find_or_create(:responding_team)] }
      team_admin_teams { [find_or_create(:team_for_admin_users, :empty)] }
    end

    factory :foi_responder do
      transient do
        identifier { "foi responding user" }
      end

      full_name        { identifier }
      email            { email_from_name(full_name) }
      responding_teams { [find_or_create(:foi_responding_team, :empty)] }
    end

    factory :sar_responder do
      transient do
        identifier { "sar responding user" }
      end

      full_name        { identifier }
      email            { email_from_name(full_name) }
      responding_teams { [find_or_create(:sar_responding_team, :empty)] }
    end

    factory :approver do
      transient do
        identifier { "approving user" }
      end

      full_name      { generate(:approver_name) }
      approving_team { create(:approving_team) }
    end

    factory :approver_responder do
      transient do
        identifier { "approving-responding user" }
      end

      full_name         { generate(:approver_responder_name) }
      approving_team    { find_or_create(:approving_team) }
      responding_teams  { [find_or_create(:responding_team)] }
    end

    factory :approver_responder_manager do
      transient do
        identifier { "approving-responding-managing user" }
      end

      full_name         { generate(:approver_responder_manager_name) }
      approving_team    { find_or_create(:approving_team) }
      responding_teams  { [find_or_create(:responding_team)] }
      managing_teams    { [find_or_create(:team_dacu)] }
    end

    factory :sar_multi_role_user do
      transient do
        identifier { "approving-responding-managing user" }
      end

      full_name         { generate(:approver_responder_manager_name) }
      approving_team    { find_or_create(:approving_team) }
      responding_teams  { [find_or_create(:sar_responding_team)] }
      managing_teams    { [find_or_create(:team_dacu)] }
    end

    factory :disclosure_specialist do
      transient do
        identifier { "disclosure-specialist approving user" }
      end

      full_name      { identifier }
      email          { email_from_name(full_name) }
      approving_team { find_or_create(:team_dacu_disclosure, :empty) }
    end

    factory :disclosure_specialist_bmt do
      transient do
        identifier { "disclosure-specialist-bmt managing user" }
      end

      full_name      { identifier }
      email          { email_from_name(full_name) }
      approving_team { find_or_create(:team_dacu_disclosure, :empty) }
      managing_teams { [find_or_create(:team_dacu, :empty)] }
    end

    factory :press_officer do
      transient do
        identifier { "press-office approving user" }
      end

      # full_name      { generate(:press_officer_name) }
      full_name      { identifier }
      email          { email_from_name(full_name) }
      approving_team { find_or_create(:team_press_office, :empty) }
    end

    factory :default_press_officer, parent: :press_officer do
      after(:create) do |user|
        CorrespondenceType.foi.update!(default_press_officer: user.email)
        CorrespondenceType.overturned_foi.update!(default_press_officer: user.email)
      end
    end

    factory :private_officer do
      transient do
        identifier { "private-office approving user" }
      end

      # full_name      { generate(:private_officer_name) }
      full_name      { identifier }
      email          { email_from_name(full_name) }
      approving_team { find_or_create(:team_private_office, :empty) }
    end

    factory :default_private_officer, parent: :private_officer do
      after(:create) do |user|
        CorrespondenceType.foi.update!(default_private_officer: user.email)
        CorrespondenceType.overturned_foi.update!(default_private_officer: user.email)
      end
    end

    factory :deactivated_user do
      transient do
        identifier { "deactivated user" }
      end

      full_name      { generate(:manager_name) }
      managing_teams { [create(:managing_team)] }
      deleted_at { Time.zone.now }
    end

    factory :admin do
      transient do
        identifier { "admin user" }
      end

      full_name      { generate(:manager_name) }
      after(:create) do |user|
        user.team_roles.create role: "admin"
      end
    end
  end
end
