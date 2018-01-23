FactoryGirl.define do
  factory :team_category_role do
    category_id   { (find_or_create :category, :foi).id }
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
      category_id   { find_or_create(:category, :foi).id }
    end

    trait :sar do
      category_id   { find_or_create(:category, :sar).id }
    end


  end
end
