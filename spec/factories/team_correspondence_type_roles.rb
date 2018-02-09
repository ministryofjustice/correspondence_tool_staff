# == Schema Information
#
# Table name: team_correspondence_type_roles
#
#  id                     :integer          not null, primary key
#  correspondence_type_id :integer
#  team_id                :integer
#  view                   :boolean          default(FALSE)
#  edit                   :boolean          default(FALSE)
#  manage                 :boolean          default(FALSE)
#  respond                :boolean          default(FALSE)
#  approve                :boolean          default(FALSE)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

FactoryGirl.define do
  factory :team_correspondence_type_role do
    correspondence_type   { find_or_create :foi_correspondence_type }
    # team_id       BusinessUnit.first.id
    view          false
    edit          false
    manage        false
    respond       false
    approve       false

    trait :responder do
      view          true
      respond       true
    end

    trait :manager do
      view          true
      manage        true
      edit          true
    end

    trait :approver do
      view          true
      approve       true
    end

    trait :foi do
      correspondence_type   { find_or_create :foi_correspondence_type }
      # category_id   { find_or_create(:category, :foi).id }
    end

    trait :sar do
      correspondence_type   { find_or_create :sar_correspondence_type }
      # category_id   { find_or_create(:category, :sar).id }
    end


  end
end
