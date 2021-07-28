require 'rails_helper'

RSpec.describe Contact, type: :model do
    let(:contact) { build(:contact) }

    let(:contact_2) { build(:contact, 
                             name: 'HMP halifax',
                             address_line_1: '123 test road',
                             address_line_2: 'little heath',
                             town: 'bakersville',
                             county: 'Mercia',
                             postcode: 'FE2 9JK',
                             contact_type: ['prison', 'probation', 'solicitor'].sample) }

    let(:contact_3) { build(:contact,
                             name: 'HMP halifax',
                             address_line_1: '123 test road',
                             postcode: 'FE2 9JK',
                             contact_type: 'university') }

  context 'validations' do
    it 'is valid if it is has a name, address_line_1 and postcode, and contact_type' do
      it { should validate_presence_of(:name) }
      it { should validate_presence_of(:address_line_1) }
      it { should validate_presence_of(:postcode)   }
      it { should validate_presence_of(:contact_type)   }
      expect(contact).to be_valid
    end

    it 'must have a valid contact_type' do
      expect(contact_2).to be_valid
      expect{ contact_3 }.to raise_exception 
    end
  end

  context 'public methods' do

    it 'can output a full concatenated address in a single line' do
      expect(contact_2.inline_address).to match('HMP halifax, 123 test road, little heath, bakersville, Mercia, FE2 9JK')
    end

    it 'can output a full concatenated multi-line address' do
      expect(contact_2.address).to match("HMP halifax\n123 test road\nlittle heath\nbakersville\nMercia\nFE2 9JK")
    end

    it 'will output correctly if optional address parts are missing' do
      expect(contact.inline_address).to match("HMP halifax, 123 test road, FE2 9JK")
      expect(contact.address).to match("HMP halifax\n123 test road\nFE2 9JK")
    end

    it 'can output the subparts of the address' do
      expect(contact_2.name).to match("HMP halifax")
      expect(contact_2.address_line_1).to match("123 test road")
      expect(contact_2.address_line_2).to match("little heath")
      expect(contact_2.town).to match("bakersville")
      expect(contact_2.county).to match("Mercia")
      expect(contact_2.postcode).to match("FE2 9JK")
      expect(contact_2.email).to match("fake.email@test098.gov.uk")
      expect(['prison', 'probation', 'solicitor']).to include(contact_2.contact_type)
    end
  end
end
