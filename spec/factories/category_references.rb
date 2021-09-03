FactoryBot.define do
  factory :category_reference do
    code { "MyString" }
    category { "MyString" }
    value { "MyString" }
    display_order { 1 }
    deactivated { false }
  end
end
