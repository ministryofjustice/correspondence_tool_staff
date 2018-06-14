require 'rails_helper'


describe CasesController do
  let(:new_date_responded) { 1.business_day.before(Date.today) }
  # let(:exemption_ids) { nil }
  let(:params) {
    {
      id: 1,
      case_foi: {
        date_responded_yyyy: new_date_responded.year,
        date_responded_mm: new_date_responded.month,
        date_responded_dd: new_date_responded.day,
        info_held_status_abbreviation: 'held',
        outcome_abbreviation: 'refused',
        refusal_reason_abbreviation: 'overturned',
        exemption_ids: ['1', '2']
      }
    }
  }

  let(:controller) {
    described_class.new.tap { |c| c.params = params }
  }
  let(:outcome_required?)        { true }
  let(:refusal_reason_required?) { true }
  let(:exemption_required?)      { true }

  before do
    allow(ClosedCaseValidator)
      .to receive(:outcome_required?).and_return(outcome_required?)
    allow(ClosedCaseValidator)
      .to receive(:refusal_reason_required?).and_return(refusal_reason_required?)
    allow(ClosedCaseValidator)
      .to receive(:exemption_required?).and_return(exemption_required?)
  end

  describe '#process_foi_closure_params' do
    it 'calls outcome_required? correctly' do
      controller.__send__(:process_foi_closure_params)

      expect(ClosedCaseValidator)
        .to have_received(:outcome_required?)
              .with(info_held_status: 'held')
    end

    it 'calls refusal_reason_required? correctly' do
      controller.__send__(:process_foi_closure_params)

      expect(ClosedCaseValidator)
        .to have_received(:refusal_reason_required?)
              .with(info_held_status: 'held')
    end

    it 'calls outcome_required? correctly' do
      controller.__send__(:process_foi_closure_params)

      expect(ClosedCaseValidator)
        .to have_received(:exemption_required?)
              .with(info_held_status: 'held',
                    outcome: 'refused',
                    refusal_reason: 'overturned')
    end

    context 'when outcome is not required' do
      subject { controller.__send__(:process_foi_closure_params).to_unsafe_hash }

      let(:outcome_required?) { false }
      it { should     include info_held_status_abbreviation: 'held' }
      it { should_not include :outcome_abbreviation }
      it { should     include outcome_id: nil  }
      it { should     include refusal_reason_abbreviation: 'overturned' }
      it { should     include exemption_ids: ['1', '2'] }
    end

    context 'when refusal reason is not required' do
      subject { controller.__send__(:process_foi_closure_params).to_unsafe_hash }
      let(:refusal_reason_required?) { false }

      it { should     include info_held_status_abbreviation: 'held' }
      it { should     include outcome_abbreviation: 'refused' }
      it { should_not include :refusal_reason_abbreviation }
      it { should     include refusal_reason_id: nil }
      it { should     include exemption_ids: ['1', '2'] }
    end

    context 'when exemption is not required' do
      subject { controller.__send__(:process_foi_closure_params).to_unsafe_hash }
      let(:exemption_required?) { false }

      it { should     include info_held_status_abbreviation: 'held' }
      it { should     include outcome_abbreviation: 'refused' }
      it { should     include refusal_reason_abbreviation: 'overturned' }
      it { should     include exemption_ids: [] }
    end

  end
end
