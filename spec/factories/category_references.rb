FactoryBot.define do
  factory :category_reference do
    category { "MyString" }
    code { "MyString" }
    value { "MyString" }
    display_order { 1 }
    deactivated { false }
  end
end
