require 'rails_helper'

describe Case::ICO::Base do
  let(:kase) { Case::ICO::Base.new() }

  describe 'search' do
    before :all do
      @case_a = create :accepted_ico_foi_case,
                       ico_reference_number: 'ICOREF1',
                       ico_officer_name: 'Bryan Adams'
      @case_b = create :accepted_ico_foi_case,
                       ico_reference_number: 'ICOREF2',
                       ico_officer_name: 'Douglas Adams'
      @case_a.update_index
      @case_b.update_index
    end

    after :all do
      DbHousekeeping.clean
    end

    it 'returns case with the matching ICO reference number' do
      expect(Case::Base.search('ICOREF1')).to match_array [@case_a]
    end

    it 'returns case with with the matching ICO officer' do
      expect(Case::Base.search('Douglas')).to match_array [@case_b]
    end
  end

  describe '.type_abbreviation' do
    subject { described_class.type_abbreviation }
    it { should eq 'ICO' }
  end

  describe 'ico_officer_name attribute' do
    it { should validate_presence_of(:ico_officer_name) }
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

  describe '#name=' do
    it 'raises a ReadOnly error' do
      expect {
        kase.name = 'something new'
      }.to raise_error(StandardError,
                       'name attribute is read-only for ICO cases')
    end
  end

  describe '#subject' do
    it 'returns the subject from the original case' do
      foi = create(:foi_case)
      ico = create(:ico_foi_case, original_case: foi)

      expect(ico.subject).to eq foi.subject
    end
  end

  describe '#subject=' do
    it 'raises a ReadOnly error' do
      foi = create(:foi_case)
      ico = create(:ico_foi_case, original_case: foi)

      expect {
        ico.subject = 'something new'
      }.to raise_error(StandardError,
                       'subject attribute is read-only for ICO cases')
    end
  end

  describe '.search' do
    it 'finds cases by ico officer name' do
      ico = create(:ico_foi_case, ico_officer_name: 'Leeroy')
      _other_ico = create(:ico_foi_case, ico_officer_name: 'Fred')
      Case::Base.update_all_indexes

      expect(Case::Base.search('Leeroy')).to eq [ico]
    end

    it 'finds cases by ico reference number' do
      ico = create(:ico_foi_case, ico_reference_number: '8888')
      _other_ico = create(:ico_foi_case, ico_reference_number: '11')
      Case::Base.update_all_indexes

      expect(Case::Base.search('8888')).to eq [ico]
    end
  end
end
