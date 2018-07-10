require 'rails_helper'

describe Case::ICO::Base do
  let(:kase) { Case::ICO::Base.new() }

  describe '.type_abbreviation' do
    subject { described_class.type_abbreviation }
    it { should eq 'ICO' }
  end

  describe 'ico_reference_number' do
    it { should validate_presence_of(:ico_reference_number) }
  end

  describe 'message' do
    it { should validate_presence_of(:message) }
  end

  describe 'external_deadline' do
    it { should validate_presence_of(:external_deadline) }
  end

  describe '#requires_flag_for_disclosure_specialists?' do
    it 'returns false' do
      kase = create :ico_foi_case
      expect(kase.requires_flag_for_disclosure_specialists?).to be false
    end
  end
end
