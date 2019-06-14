require 'rails_helper'

describe 'StatusFilter' do

  before(:all) do
    @unassigned_case              = create :case
    @closed_case_1                = create :closed_case
    @awaiting_responder_case      = create :awaiting_responder_case
    @accepted_case                = create :accepted_case
    @rejected_case                = create :rejected_case
    @case_with_response           = create :case_with_response
    @pending_dacu_clearance_case  = create :pending_dacu_clearance_case
    @approved_case                = create :approved_case
    @responded_case               = create :responded_case
    @closed_case_2                = create :closed_case
  end

  after(:all)  { DbHousekeeping.clean }

  describe '#call' do
    let(:arel)      { Case::Base.all }
    let(:service)   { StatusFilter.new(arel, params) }

    context 'open cases' do
      let(:params)    { 'open'}
      it 'returns all open cases in the arel' do
        expected_result = [
            @unassigned_case,
            @awaiting_responder_case,
            @accepted_case,
            @rejected_case,
            @case_with_response,
            @pending_dacu_clearance_case,
            @approved_case,
            @responded_case
        ]
        expect(service.call).to match_array expected_result
      end
    end

    context 'closed cases' do
      let(:params)    { 'closed' }
      it 'returns all closed cases in the arel' do
        expected_results = [ @closed_case_1, @closed_case_2 ]
        expect(service.call).to match_array expected_results
      end
    end

    context 'invalid param' do
      let(:params)    { 'semi-closed' }
      it 'raises Argument Error' do
        expect {
          service.call
        }.to raise_error ArgumentError, 'unrecognised status: semi-closed'
      end
    end
  end

end
