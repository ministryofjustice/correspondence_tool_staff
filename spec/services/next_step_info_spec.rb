require "rails_helper"

RSpec::Matchers.define :set_action_verb_to do |action_verb|
  match do |next_step_info|
    expect(next_step_info.action_verb).to eq action_verb
  end

  failure_message do |next_step_info|
    <<~EOM
      expected next step info #{next_step_info} to return action verb
      expected text: "#{action_verb}"
           got text: "#{next_step_info.action_verb}"
    EOM
  end
end

RSpec::Matchers.define :use_event do |event_name|
  match do |next_step_info|
    state_machine = next_step_info.instance_variable_get :@state_machine
    expect(state_machine).to have_received(:next_state_for_event)
                               .with(event_name,
                                     acting_user_id: disclosure_specialist.id)
                               .at_least(1).times
  end
end

# TODO: all these tests need to be rewritten to take into account that NextStepInfo throws an error when
# asked to execute an action which isn't available in that state

describe "NextStepInfo" do
  let(:responding_team)       { responder.responding_teams.first }
  let(:responder)             { find_or_create :foi_responder }
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let!(:dacu_disclosure)      { find_or_create :team_dacu_disclosure }
  let!(:press_office)         { find_or_create :team_press_office }
  let!(:private_office)       { find_or_create :team_private_office }

  context "when next state is" do
    subject { NextStepInfo.new(kase, "approve", disclosure_specialist) }

    let(:kase) { create :case_being_drafted, responder: }

    before do
      state = RSpec.current_example.metadata[:example_group][:description]
      allow(kase.state_machine).to receive(:next_state_for_event)
                                     .and_return(state)
    end

    context "unassigned" do
      it { is_expected.to have_attributes(next_team: "DACU") }
    end

    context "responded" do
      it { is_expected.to have_attributes(next_team: "DACU") }
    end

    context "closed" do
      it { is_expected.to have_attributes(next_team: "DACU") }
    end

    context "awaiting_responder" do
      it { is_expected.to have_attributes(next_team: responding_team) }
    end

    context "drafting" do
      it { is_expected.to have_attributes(next_team: responding_team) }
    end

    context "awaiting_dispatch" do
      it { is_expected.to have_attributes(next_team: responding_team) }
    end

    context "pending_dacu_clearance" do
      it { is_expected.to have_attributes(next_team: dacu_disclosure) }
    end

    context "pending_press_office_clearance" do
      it { is_expected.to have_attributes(next_team: press_office) }
    end

    context "pending_private_office_clearance" do
      it { is_expected.to have_attributes(next_team: private_office) }
    end

    context "something_unexpected" do
      it "raises an error" do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end

  context "when action is" do
    subject do
      action = RSpec.current_example.metadata[:example_group][:description]
      NextStepInfo.new(kase, action, disclosure_specialist)
    end

    let(:kase) { create :assigned_case }

    before do
      allow(kase.state_machine).to receive(:next_state_for_event)
                                     .and_return("drafting")
    end

    context "approve" do
      it { is_expected.to set_action_verb_to "clearing the response to" }
      it { is_expected.to use_event :approve }
    end

    context "request-amends" do
      it { is_expected.to set_action_verb_to "requesting amends for" }
      it { is_expected.to use_event :request_amends }
    end

    context "upload" do
      it { is_expected.to set_action_verb_to "uploading changes to" }
      it { is_expected.to use_event :add_responses }
    end

    context "upload-flagged" do
      it { is_expected.to set_action_verb_to "uploading a response to" }
      it { is_expected.to use_event :add_response_to_flagged_case }
    end

    context "upload-approve" do
      it { is_expected.to set_action_verb_to "uploading the responses and clearing" }
      it { is_expected.to use_event :upload_response_and_approve }
    end

    context "upload-redraft" do
      it { is_expected.to set_action_verb_to "uploading changes to" }
      it { is_expected.to use_event :upload_response_and_return_for_redraft }
    end

    context "unexpected-action" do
      it "raises an error" do
        expect { subject }
          .to raise_error(RuntimeError,
                          "Unexpected action parameter: 'unexpected-action'")
      end
    end
  end
end
