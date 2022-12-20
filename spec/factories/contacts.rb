FactoryBot.define do
  factory :contact do
    name { 'HMP halifax'}
    address_line_1 { '123 test road'}
    address_line_2 {}
    town {}
    county {}
    postcode { 'FE2 9JK' }
    contact_type { build_stubbed(:category_reference) }
  end
end
