require 'rails_helper'

RSpec.describe CategoryReference, type: :model do

  before do
    category_references = [
      { 
        category: 'food_types',
        code: 'apple',
        value: 'Bramley apple',
        display_order: 1,
      },
      { 
        category: 'food_types',
        code: 'bread',
        value: 'sliced bread',
        display_order: 2,
      },
      { 
        category: 'food_types',
        code: 'rice',
        value: 'sticky rice',
        display_order: 3,
      },
      { 
        category: 'food_types',
        code: 'potatoes',
        value: 'triple cooked chips',
        display_order: 4,
      },
      { 
        category: 'food_types',
        code: 'other',
        value: 'Some other food type',
        display_order: 5,
      }
    ]

    category_references.each do |category_reference|
      CategoryReference.create(category_reference)
    end
  end

  describe '#list_by_category' do
    it 'will return a hash of values for a category' do
      expected =  ['apple', 'bread', 'rice', 'potatoes', 'other']
      expect(CategoryReference.list_by_category(:food_types).size).to eq(5)
      expect(CategoryReference.list_by_category(:food_types).pluck(:code)).to eq(expected)
    end
  end

  describe '#list_value_by_category_and_code' do
    it 'will return an array of values for a category' do
      expected =  'sticky rice'
      expect(CategoryReference.display_value_by_category_and_code('food_types', 'rice')).to match(expected)
    end
  end
end
