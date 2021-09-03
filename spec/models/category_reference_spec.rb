require 'rails_helper'

RSpec.describe CategoryReference, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"

  before do

    category_references = [
      { 
        category: 'address_type',
        code: 'prison',
        value: 'Prison',
        display_order: 1,
      },
      { 
        category: 'address_type',
        code: 'probation',
        value: 'Probation centre',
        display_order: 2,
      },
      { 
        category: 'address_type',
        code: 'court',
        value: 'Court',
        display_order: 3,
      },
      { 
        category: 'address_type',
        code: 'moj_hq',
        value: '102 Petty France',
        display_order: 4,
      },
      { 
        category: 'address_type',
        code: 'other',
        value: 'Some other address type',
        display_order: 5,
      }
    ]

    category_references.each do |category_reference|
      CategoryReference.create(category_reference)
    end
  end

  describe '#find_by_category' do
    it 'will return a hash of values for a category' do
      expected = { 
        prison: "Prison",
        probation: "Probation centre",
        court: "Court",
        moj_hq: "102 Petty France",
        other: "Some other address type"
      } 
      expect(CategoryReference.find_by_category(:address_type)).to include(expected)
    end
  end
end
