require "rails_helper"

RSpec.describe Contact, type: :model do
  let(:contact) { build_stubbed(:contact) }

  let(:contact_2) do
    build_stubbed(:contact,
                  name: "HMP halifax",
                  address_line_1: "123 test road",
                  address_line_2: "little heath",
                  town: "bakersville",
                  county: "Mercia",
                  postcode: "FE2 9JK",
                  data_request_emails: "test@test.com\ntest1@test.com")
  end

  let(:contact_3) do
    build_stubbed(:contact,
                  name: "HMP halifax",
                  address_line_1: "123 test road",
                  postcode: "FE2 9JK",
                  contact_type: "university")
  end

  describe "validations" do
    it "is valid if it is has a name, address_line_1 and postcode, and contact_type" do
      expect(subject).to validate_presence_of(:name)
      expect(subject).to validate_presence_of(:address_line_1)
      expect(subject).to validate_presence_of(:postcode)
      expect(subject).to validate_presence_of(:contact_type)
      expect(contact).to be_valid
    end

    it "must have a valid contact_type" do
      expect(contact_2).to be_valid
      expect { contact_3 }.to raise_exception(ActiveRecord::AssociationTypeMismatch)
    end

    describe "data_request_emails" do
      it "is valid with one correctly formatted email" do
        contact_2.data_request_emails = "oscar@thegrouch.com"
        expect(contact_2).to be_valid
      end

      it "is valid with multiple correctly formatted emails delimited by newline" do
        contact_2.data_request_emails = "oscar@grouch.com\nbig@bird.com"
        expect(contact_2).to be_valid
      end

      it "is invalid if the only email is incorrectly formatted" do
        contact_2.data_request_emails = "bigbird.com"
        expect(contact_2).not_to be_valid
      end

      it "is invalid if any email is incorrectly formatted" do
        contact_2.data_request_emails = "oscar@grouch.com\nbigbird.com"
        expect(contact_2).not_to be_valid
      end

      it "is invalid if the wrong delimiter is used with multiple emails" do
        contact_2.data_request_emails = "oscar@grouch.com,big@bird.com"
        expect(contact_2).not_to be_valid
      end
    end
  end

  describe "public methods" do
    it "can output a full concatenated address in a single line" do
      expect(contact_2.inline_address).to match("123 test road, little heath, bakersville, Mercia, FE2 9JK")
    end

    it "can outout the display value of a contact" do
      expect(contact.contact_type_display_value).to match("Probation Office")
    end

    it "can output a full concatenated multi-line address" do
      expect(contact_2.address).to match("123 test road\nlittle heath\nbakersville\nMercia\nFE2 9JK")
    end

    it "will output correctly if optional address parts are missing" do
      expect(contact.inline_address).to match("123 test road, FE2 9JK")
      expect(contact.address).to match("123 test road\nFE2 9JK")
    end

    it "can output the subparts of the address" do
      expect(contact_2.name).to match("HMP halifax")
      expect(contact_2.address_line_1).to match("123 test road")
      expect(contact_2.address_line_2).to match("little heath")
      expect(contact_2.town).to match("bakersville")
      expect(contact_2.county).to match("Mercia")
      expect(contact_2.postcode).to match("FE2 9JK")
      expect(contact_2.contact_type).to be_a(CategoryReference)
      expect(contact_2.contact_type.value).to eq("Probation Office")
    end

    it "can output the contact display value" do
      expect(contact.contact_type_display_value).to eq("Probation Office")
    end

    it "can return an array with all email addresses" do
      expect(contact_2.all_emails).to eq ["test@test.com", "test1@test.com"]
    end
  end

  describe "class methods" do
    it "returns expected sql from #search_by_contact_name" do
      expected_sql = "SELECT \"contacts\".* FROM \"contacts\" WHERE (LOWER(name) LIKE CONCAT('%', 'LLP', '%')) ORDER BY \"contacts\".\"name\" ASC"
      expect(described_class.search_by_contact_name("LLP").to_sql).to match(expected_sql)
    end

    it "returns expected sql from #filtered_search_by_contact_name" do
      expected_sql = "SELECT \"contacts\".* FROM \"contacts\" INNER JOIN \"category_references\" ON \"category_references\".\"id\" = \"contacts\".\"contact_type_id\" WHERE (category_references.code IN ('probation,solicitor')) AND (LOWER(name) LIKE CONCAT('%', 'LLP', '%')) ORDER BY \"contacts\".\"name\" ASC"
      expect(described_class.filtered_search_by_contact_name("probation,solicitor", "LLP").to_sql).to match(expected_sql)
    end
  end
end
