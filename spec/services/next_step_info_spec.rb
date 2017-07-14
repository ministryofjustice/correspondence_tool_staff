require 'rails_helper'

RSpec::Matchers.define :set_next_state_to do |next_state|
  match do |next_step_info|
    expect(next_step_info.next_state).to eq next_state
  end

  failure_message do |next_step_info|
    <<~EOM
      expected next step info #{next_step_info} to return next state
      expected state: #{next_state}
           got state: #{next_step_info.next_state}
    EOM
  end
end

RSpec::Matchers.define :set_next_team_to do |next_team|
  match do |next_step_info|
    expect(next_step_info.next_team).to eq next_team
  end

  failure_message do |next_step_info|
    <<~EOM
      expected next step info #{next_step_info} to return next team
      expected team: #{next_team}
           got team: #{next_step_info.next_team}
    EOM
  end
end

describe 'NextStepInfo' do

  let(:unassigned_case)  { create :case }
  let(:awaiting_responder_case) { create :awaiting_responder_case }
  let(:accepted_case) { create :accepted_case }
  let(:case_with_response) { create :case_with_response }
  let(:pending_dacu_clearance_case) { create :pending_dacu_clearance_case }

  context 'invalid action' do
    it 'raises' do
      expect {
        NextStepInfo.new(unassigned_case, 'invalid-action')
      }.to raise_error RuntimeError, "Unexpected action parameter: 'invalid-action'"
    end
  end


  context 'Case in unassigned state' do
    context 'upload' do
      xit 'raises' do
        expect {
          NextStepInfo.new(unassigned_case, 'upload')
        }.to raise_error RuntimeError, 'Unexpected action upload for case in unassigned state'
      end
    end

    context 'upload-flagged' do
      xit 'raises' do
        expect {
          NextStepInfo.new(unassigned_case, 'upload-flagged')
        }.to raise_error RuntimeError, 'Unexpected action upload-flagged for case in unassigned state'
      end
    end

    context 'upload-approve' do
      xit 'raises' do
        expect {
          NextStepInfo.new(unassigned_case, 'upload-approve')
        }.to raise_error RuntimeError, 'Unexpected action upload-approve for case in unassigned state'
      end
    end

    context 'upload-redraft' do
      xit 'raises' do
        expect {
          NextStepInfo.new(unassigned_case, 'upload-redraft')
        }.to raise_error RuntimeError, 'Unexpected action upload-redraft for case in unassigned state'
      end
    end
  end

  context 'Case in awaiting_responder state' do
    context 'upload' do
      xit 'raises' do
        expect {
          NextStepInfo.new(awaiting_responder_case, 'upload')
        }.to raise_error RuntimeError, 'Unexpected action upload for case in awaiting_responder state'
      end
    end

    context 'upload-flagged' do
      xit 'raises' do
        expect {
          NextStepInfo.new(awaiting_responder_case, 'upload-flagged')
        }.to raise_error RuntimeError, 'Unexpected action upload-flagged for case in awaiting_responder state'
      end
    end

    context 'upload-approve' do
      xit 'raises' do
        expect {
          NextStepInfo.new(awaiting_responder_case, 'upload-approve')
        }.to raise_error RuntimeError, 'Unexpected action upload-approve for case in awaiting_responder state'
      end
    end

    context 'upload-redraft' do
      xit 'raises' do
        expect {
          NextStepInfo.new(awaiting_responder_case, 'upload-redraft')
        }.to raise_error RuntimeError, 'Unexpected action upload-redraft for case in awaiting_responder state'
      end
    end
  end

  context 'Case in drafting state' do
    context 'upload' do
      it 'calculates next step and team' do
        nsi = NextStepInfo.new(accepted_case, 'upload')
        expect(nsi.next_state).to eq 'awaiting_dispatch'
        expect(nsi.next_team).to eq accepted_case.responding_team
      end
    end

    context 'upload-flagged' do
      it 'calculates next step and team' do
        nsi = NextStepInfo.new(accepted_case, 'upload')
        expect(nsi.next_state).to eq 'awaiting_dispatch'
        expect(nsi.next_team).to eq accepted_case.responding_team
      end
    end

    context 'upload-approve' do
      xit 'raises' do
        expect {
          NextStepInfo.new(accepted_case, 'upload-approve')
        }.to raise_error RuntimeError, 'Unexpected action upload-approve for case in drafting state'
      end
    end

    context 'upload-redraft' do
      xit 'raises' do
        expect {
          NextStepInfo.new(accepted_case, 'upload-redraft')
        }.to raise_error RuntimeError, 'Unexpected action upload-redraft for case in drafting state'
      end
    end
  end

  context 'Case in awaiting_dispatch state' do
    context 'upload' do
      it 'calculates next step and team' do
        nsi = NextStepInfo.new(case_with_response, 'upload')
        expect(nsi.next_state).to eq 'awaiting_dispatch'
        expect(nsi.next_team).to eq case_with_response.responding_team
      end
    end

    context 'upload-flagged' do
      it 'raises' do
        nsi = NextStepInfo.new(case_with_response, 'upload')
        expect(nsi.next_state).to eq 'awaiting_dispatch'
        expect(nsi.next_team).to eq case_with_response.responding_team
      end
    end

    context 'upload-approve' do
      xit 'raises' do
        expect {
          NextStepInfo.new(case_with_response, 'upload-approve')
        }.to raise_error RuntimeError, 'Unexpected action upload-approve for case in awaiting_dispatch state'
      end
    end

    context 'upload-redraft' do
      xit 'raises' do
        expect {
          NextStepInfo.new(case_with_response, 'upload-redraft')
        }.to raise_error RuntimeError, 'Unexpected action upload-redraft for case in awaiting_dispatch state'
      end
    end
  end

  context 'Case in pending_dacu_clearance state' do
    context 'upload' do
      xit 'calculates next step and team' do
        expect {
          NextStepInfo.new(pending_dacu_clearance_case, 'upload')
        }.to raise_error RuntimeError, 'Unexpected action upload for case in pending_dacu_clearance state'
      end
    end

    context 'upload-flagged' do
      xit 'raises' do
        expect {
          NextStepInfo.new(pending_dacu_clearance_case, 'upload-flagged')
        }.to raise_error RuntimeError, 'Unexpected action upload-flagged for case in pending_dacu_clearance state'
      end
    end

    context 'upload-approve' do
      it 'raises' do
        nsi = NextStepInfo.new(pending_dacu_clearance_case, 'upload-approve')
        expect(nsi.next_state).to eq 'awaiting_dispatch'
        expect(nsi.next_team).to eq pending_dacu_clearance_case.responding_team
      end
    end

    context 'upload-redraft' do
      it 'raises' do
        nsi = NextStepInfo.new(pending_dacu_clearance_case, 'upload-redraft')
        expect(nsi.next_state).to eq 'drafting'
        expect(nsi.next_team).to eq pending_dacu_clearance_case.responding_team
      end
    end
  end

  context 'case is pending_dacu_clearance and flagged for press office' do
    let(:press_office) { find_or_create :team_press_office}
    let(:kase)         { create :pending_dacu_clearance_case, :press_office }

    describe 'approve action' do
      subject { NextStepInfo.new(kase, 'approve') }

      it { should set_next_state_to 'pending_press_office_clearance' }
      it { should set_next_team_to press_office }
    end

    describe 'upload' do
      xit 'raises an error' do
        expect {
          NextStepInfo.new(kase, 'upload')
        }.to raise_error RuntimeError, 'Unexpected action upload for case in pending_dacu_clearance state'
      end
    end
  end
end
