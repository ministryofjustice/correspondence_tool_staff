# == Schema Information
#
# Table name: correspondence_types
#
#  id           :integer          not null, primary key
#  name         :string
#  abbreviation :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  properties   :jsonb
#

require 'rails_helper'

describe CorrespondenceType, type: :model do
  let(:foi) { create(:foi_correspondence_type) }
  let(:ico) { create(:ico_correspondence_type) }
  let(:sar) { create(:sar_correspondence_type) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:abbreviation) }
  it { should validate_presence_of(:escalation_time_limit) }
  it { should validate_presence_of(:internal_time_limit) }
  it { should validate_presence_of(:external_time_limit) }

  it { should have_attributes(default_press_officer: nil,
                              default_private_officer: nil)}

  describe '.ico' do
    it 'finds the ICO correspondence type' do
      ico = find_or_create :ico_correspondence_type
      expect(described_class.ico).to eq ico
    end
  end

  describe 'teams' do
    it 'lists teams that can handle this correspondence type' do
      ct1    = create(:correspondence_type, name: 'ct1', abbreviation: 'ct1')
      ct2    = create(:correspondence_type, name: 'ct2', abbreviation: 'ct2')
      team1a = create(:business_unit, correspondence_types: [ct1])
      team1b = create(:business_unit, correspondence_types: [ct1])
      _team2 = create(:business_unit, correspondence_types: [ct2])
      expect(ct1.teams).to eq [team1a, team1b]
    end
  end

  describe 'deadline_calculator_class' do
    it { should validate_presence_of(:deadline_calculator_class) }
    it 'allows the value CalendarDays' do
      ct = CorrespondenceType.new name: 'Calendar Days Test',
                                  abbreviation: 'CDT',
                                  escalation_time_limit: 1,
                                  internal_time_limit: 1,
                                  external_time_limit: 1,
                                  deadline_calculator_class: 'CalendarDays'
      expect(ct).to be_valid
    end

    it 'allows the value BusinessDays' do
      ct = CorrespondenceType.new name: 'Business Days Test',
                                  abbreviation: 'BDT',
                                  escalation_time_limit: 1,
                                  internal_time_limit: 1,
                                  external_time_limit: 1,
                                  deadline_calculator_class: 'BusinessDays'
      expect(ct).to be_valid
    end

    it 'does not allow other values' do
      expect {
        CorrespondenceType.new name: 'Invalid Class Test',
                               abbreviation: 'IDT',
                               escalation_time_limit: 1,
                               internal_time_limit: 1,
                               external_time_limit: 1,
                               deadline_calculator_class: 'Invalid Class'
      }.to raise_error(ArgumentError)
    end
  end

  describe '.by_report_category' do

    let(:cts)  { CorrespondenceType.by_report_category }

    it 'returns only those correspondence types where report_category_name is pressent' do
      expect(CorrespondenceType.all.size).to eq 3
      expect(cts.size).to eq 2
    end

    it 'returns them in alphabetic order of report category name' do
      expect(cts.map(&:report_category_name)).to eq [ 'FOI report', 'SAR report' ]
    end
  end

  describe '#sub_classes' do
    it 'returns FOI sub-classes' do
      expect(foi.sub_classes).to eq [Case::FOI::Standard,
                                     Case::FOI::TimelinessReview,
                                     Case::FOI::ComplianceReview]
    end

    it 'returns ICO sub-classes' do
      expect(ico.sub_classes).to eq [Case::ICO::FOI,
                                     Case::ICO::SAR]
    end

    it 'returns SAR sub-classes' do
      expect(sar.sub_classes).to eq [Case::SAR]
    end
  end
end
