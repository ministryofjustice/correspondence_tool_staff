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
require "rails_helper"

RSpec.describe CategoryReference, type: :model do
  before do
    category_references = [
      {
        category: "food_types",
        code: "apple",
        value: "Bramley apple",
        display_order: 1,
      },
      {
        category: "food_types",
        code: "bread",
        value: "sliced bread",
        display_order: 2,
      },
      {
        category: "food_types",
        code: "rice",
        value: "sticky rice",
        display_order: 3,
      },
      {
        category: "food_types",
        code: "potatoes",
        value: "triple cooked chips",
        display_order: 4,
      },
      {
        category: "food_types",
        code: "other",
        value: "Some other food type",
        display_order: 5,
      },
    ]

    category_references.each do |category_reference|
      described_class.create(category_reference)
    end
  end

  describe "#list_by_category" do
    it "returns a hash of values for a category" do
      expected = %w[apple bread rice potatoes other]
      expect(described_class.list_by_category(:food_types).size).to eq(5)
      expect(described_class.list_by_category(:food_types).pluck(:code)).to eq(expected)
    end
  end
end
