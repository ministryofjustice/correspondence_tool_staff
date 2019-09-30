require 'rails_helper'

RSpec.describe LetterTemplate, type: :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:abbreviation) }
  it { should validate_presence_of(:body) }
  it { should validate_presence_of(:template_type) }

  it { should have_enum(:template_type).
          with_values(['acknowledgement', 'dispatch']) }

  context 'validate uniqueness of abbreviation' do
    it 'errors if not unique' do
      create :letter_template, abbreviation: 'abc'
      t2 = build_stubbed :letter_template, abbreviation: 'abc'
      expect(t2).not_to be_valid
      expect(t2.errors[:abbreviation]).to eq ['has already been taken']
    end
  end

  describe 'self.type_name' do
    it 'returns the correct string for a valid type' do
      expect(LetterTemplate.type_name('dispatch')).to eq 'dispatch'
      expect(LetterTemplate.type_name('acknowledgement')).to eq 'acknowledgement'
    end

    it 'returns "unknown" for an invalid type' do
      expect(LetterTemplate.type_name('foo')).to eq 'unknown'
    end
  end

  describe 'render' do
    let(:letter_template) { create(:letter_template) }
    it 'renders a template' do
      values = OpenStruct.new(name: "Bob")
      expect(letter_template.render(values))
        .to match "Thank you for your offender subject access request, Bob"
    end
  end
end
