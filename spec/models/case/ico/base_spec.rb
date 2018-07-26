require 'rails_helper'

describe Case::ICO::Base do
  let(:kase) { Case::ICO::Base.new() }

  describe '.type_abbreviation' do
    subject { described_class.type_abbreviation }
    it { should eq 'ICO' }
  end

  describe 'ico_reference_number attribute' do
    it { should validate_presence_of(:ico_reference_number) }
  end

  describe 'message attribute' do
    it { should validate_presence_of(:message) }
  end

  describe 'external_deadline attribute' do
    it { should validate_presence_of(:external_deadline) }
  end

  describe 'original_case association' do
    it { should have_one(:original_case)
                  .through(:original_case_link)
                  .source(:linked_case) }

    it 'validates that the case can be associated as an original case' do
      linked_case = create(:ico_foi_case)
      ico = build(:ico_foi_case, original_case: linked_case)
      expect(ico).not_to be_valid
      expect(ico.errors[:original_case])
        .to eq ["can't link a ICO Appeal - FOI case to a ICO Appeal - FOI as a original case"]
    end

    it "validates that a case isn't both original and related" do
      foi = create(:foi_case)
      ico = build(:ico_foi_case, original_case: foi, related_cases: [foi])
      expect(ico).not_to be_valid
      expect(ico.errors[:linked_cases])
        .to eq ['already linked as the original case']
    end

    it 'validates that original case is present' do
      ico = create(:ico_foi_case)
      ico.original_case = nil
      ico.valid?
      expect(ico.errors[:original_case]).to eq ["can't be blank"]
    end
  end

  describe 'original_case_link association' do
    it { should have_one(:original_case_link)
                  .class_name('LinkedCase')
                  .with_foreign_key('case_id') }
  end

  describe '#original_case_id' do
    it 'finds case and assigns to original_case' do
      foi = create(:foi_case)
      ico = build(:ico_foi_case, original_case: nil)
      ico.original_case_id = foi.id
      expect(ico).to be_valid
      expect(ico.original_case).to eq foi
    end
  end

  describe 'case_links association' do
    it 'validates that the original case is not already related' do
      foi = create(:foi_case)
      ico = create(:ico_foi_case, related_cases: [foi])
      expect(ico).to be_valid
      ico.original_case = foi
      ico.save
      expect(ico).not_to be_valid
    end
  end

  describe '#requires_flag_for_disclosure_specialists?' do
    it 'returns false' do
      kase = create :ico_foi_case
      expect(kase.requires_flag_for_disclosure_specialists?).to be false
    end
  end
end
