FactoryBot.define do
  factory :category_reference do
    category { "contact_type" }
    code { "probation" }
    value { "Probation Office" }
    display_order { 1 }
    deactivated { false }
  end
  
end
