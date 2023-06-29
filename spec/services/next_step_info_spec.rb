require "rails_helper"

RSpec::Matchers.define :set_action_verb_to do |action_verb|
  match do |next_step_info|
    expect(next_step_info.action_verb).to eq action_verb
  end

  failure_message do |next_step_info|
    <<~INFO
      expected next step info #{next_step_info} to return action verb
      expected text: "#{action_verb}"
           got text: "#{next_step_info.action_verb}"
    INFO
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

describe NextStepInfo do
  let(:responding_team)       { responder.responding_teams.first }
  let(:responder)             { find_or_create :foi_responder }
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let!(:dacu_disclosure)      { find_or_create :team_dacu_disclosure }
  let!(:press_office)         { find_or_create :team_press_office }
  let!(:private_office)       { find_or_create :team_private_office }

  describe "next state" do
    subject(:next_step_info) { described_class.new(kase, "approve", disclosure_specialist) }

    let(:kase) { create :case_being_drafted, responder: }

    before do
      allow(kase.state_machine).to receive(:next_state_for_event).and_return(state)
    end

    context "when unassigned" do
      let(:state) { "unassigned" }

      it { is_expected.to have_attributes(next_team: "DACU") }
    end

    context "when responded" do
      let(:state) { "responded" }

      it { is_expected.to have_attributes(next_team: "DACU") }
    end

    context "when closed" do
      let(:state) { "closed" }

      it { is_expected.to have_attributes(next_team: "DACU") }
    end

    context "when awaiting_responder" do
      let(:state) { "awaiting_responder" }

      it { is_expected.to have_attributes(next_team: responding_team) }
    end

    context "when drafting" do
      let(:state) { "drafting" }

      it { is_expected.to have_attributes(next_team: responding_team) }
    end

    context "when awaiting_dispatch" do
      let(:state) { "awaiting_dispatch" }

      it { is_expected.to have_attributes(next_team: responding_team) }
    end

    context "when pending_dacu_clearance" do
      let(:state) { "pending_dacu_clearance" }

      it { is_expected.to have_attributes(next_team: dacu_disclosure) }
    end

    context "when pending_press_office_clearance" do
      let(:state) { "pending_press_office_clearance" }

      it { is_expected.to have_attributes(next_team: press_office) }
    end

    context "when pending_private_office_clearance" do
      let(:state) { "pending_private_office_clearance" }

      it { is_expected.to have_attributes(next_team: private_office) }
    end

    context "when something_unexpected" do
      let(:state) { "something_unexpected" }

      it "raises an error" do
        expect { next_step_info }.to raise_error(RuntimeError)
      end
    end
  end

  describe "action" do
    subject(:next_step_info) do
      described_class.new(kase, action, disclosure_specialist)
    end

    let(:kase) { create :assigned_case }

    before do
      allow(kase.state_machine).to receive(:next_state_for_event).and_return("drafting")
    end

    context "when approve" do
      let(:action) { "approve" }

      it { is_expected.to set_action_verb_to "clearing the response to" }
      it { is_expected.to use_event :approve }
    end

    context "when request-amends" do
      let(:action) { "request-amends" }

      it { is_expected.to set_action_verb_to "requesting amends for" }
      it { is_expected.to use_event :request_amends }
    end

    context "when upload" do
      let(:action) { "upload" }

      it { is_expected.to set_action_verb_to "uploading changes to" }
      it { is_expected.to use_event :add_responses }
    end

    context "when upload-flagged" do
      let(:action) { "upload-flagged" }

      it { is_expected.to set_action_verb_to "uploading a response to" }
      it { is_expected.to use_event :add_response_to_flagged_case }
    end

    context "when upload-approve" do
      let(:action) { "upload-approve" }

      it { is_expected.to set_action_verb_to "uploading the responses and clearing" }
      it { is_expected.to use_event :upload_response_and_approve }
    end

    context "when upload-redraft" do
      let(:action) { "upload-redraft" }

      it { is_expected.to set_action_verb_to "uploading changes to" }
      it { is_expected.to use_event :upload_response_and_return_for_redraft }
    end

    context "when unexpected-action" do
      let(:action) { "unexpected-action" }

      it "raises an error" do
        expect { next_step_info }
          .to raise_error(RuntimeError,
                          "Unexpected action parameter: 'unexpected-action'")
      end
    end
  end
end
