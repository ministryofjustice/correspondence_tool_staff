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

  describe 'original_case_id attribute' do
    it 'populates original_case after creation' do
      foi_case = create(:foi_case)
      new_case = build(:ico_foi_case)
      new_case.original_case_id = foi_case.id
      new_case.save!
      expect(new_case.original_case).to eq foi_case
    end
  end

  describe 'original_case association' do
    it { should have_one(:original_case)
                  .through(:original_case_link)
                  .source(:linked_case) }
  end

  describe 'original_case_link association' do
    it { should have_one(:original_case_link)
                  .class_name('LinkedCase')
                  .with_foreign_key('case_id') }
  end

  describe '#requires_flag_for_disclosure_specialists?' do
    it 'returns false' do
      kase = create :ico_foi_case
      expect(kase.requires_flag_for_disclosure_specialists?).to be false
    end
  end
end
