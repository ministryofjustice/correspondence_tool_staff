# == Schema Information
#
# Table name: category_references
#
#  id            :bigint           not null, primary key
#  category      :string
#  code          :string
#  value         :string
#  display_order :integer
#  deactivated   :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
FactoryBot.define do
  factory :category_reference do
    category { "contact_type" }
    code { "probation" }
    value { "Probation Office" }
    display_order { 1 }
    deactivated { false }
  end
end
