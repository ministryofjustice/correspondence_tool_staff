require 'rails_helper'

module Stats
  describe R901OffenderSarCasesReport do
    after(:all) { DbHousekeeping.clean(seed: true) }

    describe '.title' do
      it 'returns correct title' do
        expect(described_class.title).to eq 'Cases report for Offender SAR'
      end
    end

    describe '.description' do
      it 'returns correct description' do
        expect(described_class.description)
          .to eq 'The list of Offender SAR cases within allowed and filtered scope'
      end
    end

    describe '#case_scope' do
      before do
        create_report_type(abbr: :r901)
      end

      before(:all) do
        @sar_1 = create :accepted_sar, identifier: 'sar-1'
        @offender_sar_1 = create :offender_sar_case, :waiting_for_data, identifier: 'osar-1'

        @sar_2 = create :accepted_ico_foi_case, identifier: 'sar-2'
        @offender_sar_2 = create :offender_sar_case, :closed, identifier: 'osar-2'

        @sar_3 = create :accepted_sar, identifier: 'sar-3'
        @offender_sar_3 = create :offender_sar_case, :data_to_be_requested, identifier: 'osar-3'

        @sar_4 = create :accepted_sar, identifier: 'sar-4'
        @offender_sar_4 = create :offender_sar_case, :ready_to_copy, identifier: 'osar-4'
      end

      it 'returns only Offender SAR cases with initial scope of nil' do
        report = described_class.new()
        expect(report.case_scope).to match_array( [@offender_sar_1, @offender_sar_2, @offender_sar_3, @offender_sar_4])
      end

      it 'returns only Offender SAR cases with initial scope of ready-to-copy cases being asked' do
        report = described_class.new(case_scope: Case::SAR::Offender.all.where(current_state: 'ready_to_copy'))
        expect(report.case_scope).to match_array( [@offender_sar_4])
      end
    end
  end
end
