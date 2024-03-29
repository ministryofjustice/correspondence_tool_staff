require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe "event machine" do
  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end

  before(:all) do
    @setup = StandardSetup.new(
      only_cases: %i[
        sar_noff_unassigned
        sar_noff_awresp
        sar_noff_draft
        sar_noff_closed
        sar_noff_trig_awdis
        sar_noff_trig_awresp
        sar_noff_trig_awresp_accepted
        sar_noff_trig_draft
        sar_noff_trig_draft_accepted
      ],
    )
  end

  after(:all) do
    DbHousekeeping.clean(seed: true)
  end

  describe "assign_to_new_team" do
    let(:event) { :assign_to_new_team }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
        %i[disclosure_bmt sar_noff_awresp],
        %i[disclosure_bmt sar_noff_draft],
        %i[disclosure_bmt sar_noff_trig_awresp],
        %i[disclosure_bmt sar_noff_trig_awresp_accepted],
        %i[disclosure_bmt sar_noff_trig_draft],
        %i[disclosure_bmt sar_noff_trig_draft_accepted],
      ).with_transition_to(:awaiting_responder)
    }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
        %i[disclosure_bmt sar_noff_closed],
      ).with_transition_to(:closed)
    }

    it {
      expect(event).to have_after_hook(
        %i[disclosure_bmt sar_noff_awresp],
        %i[disclosure_bmt sar_noff_draft],
        %i[disclosure_bmt sar_noff_trig_awresp],
        %i[disclosure_bmt sar_noff_trig_awresp_accepted],
        %i[disclosure_bmt sar_noff_trig_draft],
        %i[disclosure_bmt sar_noff_trig_draft_accepted],
      ).with_hook("Workflows::Hooks", :assign_responder_email)
    }
  end

  describe "update_closure" do
    let(:event) { :update_closure }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
        %i[sar_responder sar_noff_closed],
        %i[another_sar_responder_in_same_team sar_noff_closed],
        %i[disclosure_bmt sar_noff_closed],
      )
    }
  end

  ############## EMAIL TESTS ################

  describe "add_message_to_case" do
    let(:event) { :add_message_to_case }

    it {
      expect(event).to have_after_hook(
        %i[disclosure_bmt sar_noff_draft],
        %i[disclosure_bmt sar_noff_trig_draft],
        %i[disclosure_bmt sar_noff_trig_draft_accepted],
        %i[disclosure_bmt sar_noff_trig_awdis],
        %i[disclosure_specialist sar_noff_trig_draft_accepted],
        %i[disclosure_specialist sar_noff_trig_awdis],
        %i[sar_responder sar_noff_draft],
        %i[sar_responder sar_noff_trig_draft],
        %i[sar_responder sar_noff_trig_draft_accepted],
        %i[sar_responder sar_noff_trig_awdis],
        %i[another_sar_responder_in_same_team sar_noff_draft],
        %i[another_sar_responder_in_same_team sar_noff_trig_draft],
        %i[another_sar_responder_in_same_team sar_noff_trig_draft_accepted],
        %i[another_sar_responder_in_same_team sar_noff_trig_awdis],
      ).with_hook("Workflows::Hooks", :notify_responder_message_received)
    }
  end

  describe "assign_responder" do
    let(:event) { :assign_responder }

    it {
      expect(event).to have_after_hook(
        %i[disclosure_bmt sar_noff_unassigned],
      ).with_hook("Workflows::Hooks", :assign_responder_email)
    }
  end

  describe "close" do
    let(:event) { :close }

    it {
      expect(event).to have_after_hook(
        %i[sar_responder sar_noff_draft],
        %i[sar_responder sar_noff_trig_awdis],
        %i[another_sar_responder_in_same_team sar_noff_draft],
        %i[another_sar_responder_in_same_team sar_noff_trig_awdis],
      ).with_hook("Workflows::Hooks", :notify_managing_team_case_closed)
    }
  end

  describe "reassign_user" do
    let(:event) { :reassign_user }

    it {
      expect(event).to have_after_hook(
        %i[disclosure_specialist sar_noff_trig_awdis],
        %i[disclosure_specialist sar_noff_trig_awresp_accepted],
        %i[disclosure_specialist sar_noff_trig_draft_accepted],
        %i[disclosure_specialist_coworker sar_noff_trig_awdis],
        %i[disclosure_specialist_coworker sar_noff_trig_awresp_accepted],
        %i[disclosure_specialist_coworker sar_noff_trig_draft_accepted],
        %i[sar_responder sar_noff_draft],
        %i[sar_responder sar_noff_trig_awdis],
        %i[sar_responder sar_noff_trig_draft_accepted],
        %i[sar_responder sar_noff_trig_draft],
        %i[another_sar_responder_in_same_team sar_noff_draft],
        %i[another_sar_responder_in_same_team sar_noff_trig_awdis],
        %i[another_sar_responder_in_same_team sar_noff_trig_draft_accepted],
        %i[another_sar_responder_in_same_team sar_noff_trig_draft],
      ).with_hook("Workflows::Hooks", :reassign_user_email)
    }
  end

  describe "progress_for_clearance" do
    let(:event) { :progress_for_clearance }

    it {
      expect(event).to have_after_hook(
        %i[sar_responder sar_noff_trig_draft_accepted],
        %i[sar_responder sar_noff_trig_draft],
        %i[another_sar_responder_in_same_team sar_noff_trig_draft_accepted],
        %i[another_sar_responder_in_same_team sar_noff_trig_draft],
      ).with_hook("Workflows::Hooks", :notify_approver_ready_for_review)
    }
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
