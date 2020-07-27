require 'rails_helper'

module Stats
  describe R300GeneralOpenCasesReport do
    after(:all) { DbHousekeeping.clean(seed: true) }

    describe '.title' do
      it 'returns correct title' do
        expect(described_class.title).to eq 'Open cases report'
      end
    end

    describe '.description' do
      it 'returns correct description' do
        expect(described_class.description)
          .to eq 'The list of open within allowed and filtered scope'
      end
    end

    describe '#case_scope' do
      before do
        create_report_type(abbr: :r300)
      end

      before(:all) do
        @sar_1 = create :accepted_sar, identifier: 'sar-1'
        @offender_sar_1 = create :offender_sar_case, :waiting_for_data, identifier: 'osar-1'

        @foi_1 = create :accepted_ico_foi_case, identifier: 'foi-1'
        @offender_sar_2 = create :offender_sar_case, :closed, identifier: 'osar-2'

        @sar_2 = create :accepted_sar, identifier: 'sar-3'
        @offender_sar_3 = create :offender_sar_case, :data_to_be_requested, identifier: 'osar-3'
      end

      it 'returns all open cases with initial scope of nil' do
        report = described_class.new()
        expect(report.case_scope).to match_array( [@sar_1, @foi_1, @offender_sar_1, @sar_2, @offender_sar_3])
      end

      it 'returns all open foi cases with initial scope of only ico_foi being asked' do
        report = described_class.new(case_scope: Case::Base.all.where(type: 'Case::ICO::FOI'))
        expect(report.case_scope).to match_array( [@foi_1])
      end
    end
  end
end
