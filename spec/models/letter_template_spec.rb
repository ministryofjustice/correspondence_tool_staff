require "rails_helper"

RSpec.describe LetterTemplate, type: :model do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:abbreviation) }
  it { is_expected.to validate_presence_of(:body) }
  it { is_expected.to validate_presence_of(:template_type) }

  it {
    expect(described_class.new).to have_enum(:template_type)
          .with_values(%w[acknowledgement dispatch])
  }

  context "when validate uniqueness of abbreviation" do
    it "errors if not unique" do
      create :letter_template, abbreviation: "abc"
      t2 = build_stubbed :letter_template, abbreviation: "abc"
      expect(t2).not_to be_valid
      expect(t2.errors[:abbreviation]).to eq ["has already been taken"]
    end
  end

  describe "self.type_name" do
    it "returns the correct string for a valid type" do
      expect(described_class.type_name("dispatch")).to eq "dispatch"
      expect(described_class.type_name("acknowledgement")).to eq "acknowledgement"
    end

    it 'returns "unknown" for an invalid type' do
      expect(described_class.type_name("foo")).to eq "unknown"
    end
  end

  describe "render" do
    let(:letter_template) { create(:letter_template) }

    it "renders a template" do
      values = OpenStruct.new(name: "Bob")
      expect(letter_template.render(values, letter_template, "body"))
        .to match "Thank you for your offender subject access request, Bob"
    end
  end
  
  describe "#telephone_number" do
    context "when letter template is dispatch letter" do
      let(:letter_template) { create(:letter_template, template_type: "dispatch", name: "Letter to Recipient") }

      it "returns telephone number for dispatch letter" do
        expect(letter_template.telephone_number).to eq(LetterTemplate::DISPATCH_LETTER_TEL_NUM)
      end
    end

    context "when letter template is acknowledgement letter" do
      let(:letter_template) { create(:letter_template, template_type: "acknowledgement", name: "Letter to Recipient") }

      it "returns telephone number for acknowledgement letter" do
        expect(letter_template.telephone_number).to eq(LetterTemplate::ACKNOWLEDGEMENT_LETTER_TEL_NUM)
      end
    end
  end
end
