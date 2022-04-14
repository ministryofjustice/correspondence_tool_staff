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
  factory :directorate do
    transient do
      lead { create :director }
    end

    sequence(:name) { |n| "Directorate #{n}" }
    email { name.downcase.gsub(/\W/, '_') + '@localhost' }
    business_group { find_or_create :business_group }

    after(:create) do |dir, evaluator|
      dir.properties << evaluator.lead
    end
  end

  factory :responder_directorate, parent: :directorate do
    name           { 'Responder Directorate' }
    email          { 'responder-dir@localhost' }
    business_group { find_or_create :responder_business_group }
  end

  factory :dacu_directorate, parent: :directorate do
    name           { 'DACU Directorate' }
    email          { 'dacu@localhost' }
    business_group { find_or_create :operations_business_group }
  end

  factory :press_office_directorate, parent: :directorate do
    name           { 'Press Office Directorate' }
    email          { 'press_office@localhost' }
    business_group { find_or_create :operations_business_group }
  end

  factory :private_office_directorate, parent: :directorate do
    name           { 'Private Office Directorate' }
    email          { 'private_office@localhost' }
    business_group { find_or_create :operations_business_group }
  end

  factory :deactivated_directorate, parent: :directorate do
    name           { 'Deactivated Directorate' }
    email          { 'deactivated-dir@localhost' }
    business_group { find_or_create :responder_business_group }
    deleted_at     { Time.zone.now }
  end
end
