require 'rails_helper'

RSpec.describe Contact, type: :model do
    let(:contact) { build(:contact) }

    let(:contact_2) { build(:contact, 
                             name: 'HMP halifax',
                             address_line_1: '123 test road',
                             address_line_2: 'little heath',
                             town: 'bakersville',
                             county: 'Mercia',
                             postcode: 'FE2 9JK') }

    let(:contact_3) { build(:contact,
                             name: 'HMP halifax',
                             address_line_1: '123 test road',
                             postcode: 'FE2 9JK',
                             contact_type: 'university') }
    let(:contact_4) { build(:contact, 
                             name: 'HMP halifax',
                             address_line_1: '123 test road',
                             address_line_2: 'little heath',
                             town: 'bakersville',
                             county: 'Mercia',
                             postcode: 'FE2 9JK',
                             email: 'test@test.com' ) }
  context 'validations' do
    it 'is valid if it is has a name, address_line_1 and postcode, contact_type and email if of type prison' do
      should validate_presence_of(:name)
      should validate_presence_of(:address_line_1)
      should validate_presence_of(:postcode)
      should validate_presence_of(:contact_type)
      byebug
      if contact.contact_type.code == 'prison' 
      should validate_presence_of(:email)
      end
      expect(contact).to be_valid
    end

    it 'must have a valid contact_type' do
      expect(contact_2).to be_valid
      expect{ contact_3 }.to raise_exception(ActiveRecord::AssociationTypeMismatch)
    end
  end

  context 'public methods' do

    it 'can output a full concatenated address in a single line' do
      expect(contact_2.inline_address).to match('123 test road, little heath, bakersville, Mercia, FE2 9JK')
    end

    it 'can outout the display value of a contact' do
      expect(contact.contact_type_display_value).to match('Probation Office')
    end

    it 'can output a full concatenated multi-line address' do
      expect(contact_2.address).to match("123 test road\nlittle heath\nbakersville\nMercia\nFE2 9JK")
    end

    it 'will output correctly if optional address parts are missing' do
      expect(contact.inline_address).to match("123 test road, FE2 9JK")
      expect(contact.address).to match("123 test road\nFE2 9JK")
    end

    it 'can output the subparts of the address' do
      expect(contact_2.name).to match("HMP halifax")
      expect(contact_2.address_line_1).to match("123 test road")
      expect(contact_2.address_line_2).to match("little heath")
      expect(contact_2.town).to match("bakersville")
      expect(contact_2.county).to match("Mercia")
      expect(contact_2.postcode).to match("FE2 9JK")
      expect(contact_2.email).to match("fake.email@test098.gov.uk")
      expect(contact_2.contact_type).to be_a(CategoryReference)
      expect(contact_2.contact_type.value).to eq("Probation Office")
    end

     it 'can validate email if contact type is prison' do
      expect(contact_4.name).to match("HMP halifax")
      expect(contact_4.address_line_1).to match("123 test road")
      expect(contact_4.address_line_2).to match("little heath")
      expect(contact_4.town).to match("bakersville")
      expect(contact_4.county).to match("Mercia")
      expect(contact_4.postcode).to match("FE2 9JK")
      expect(contact_4.email).to match("test@test.com")
      expect(contact_4.contact_type).to be_a(CategoryReference)
      expect(contact_4.contact_type.value).to eq("Probation Office")
    end

    it 'can output the contact display value' do
      expect(contact.contact_type_display_value).to eq("Probation Office")
    end

  end

  context 'class methods' do
    it 'returns expected sql from #search_by_contact_name' do
      expected_sql = "SELECT \"contacts\".* FROM \"contacts\" WHERE (LOWER(name) LIKE CONCAT('%', 'LLP', '%')) ORDER BY \"contacts\".\"name\" ASC" 
      expect(Contact.search_by_contact_name('LLP').to_sql).to match(expected_sql)
    end

    it 'returns expected sql from #filtered_search_by_contact_name' do
      expected_sql = "SELECT \"contacts\".* FROM \"contacts\" INNER JOIN \"category_references\" ON \"category_references\".\"id\" = \"contacts\".\"contact_type_id\" WHERE (category_references.code IN ('probation,solicitor')) AND (LOWER(name) LIKE CONCAT('%', 'LLP', '%')) ORDER BY \"contacts\".\"name\" ASC"
      expect(Contact.filtered_search_by_contact_name("probation,solicitor",'LLP').to_sql).to match(expected_sql)
    end
  end
end
