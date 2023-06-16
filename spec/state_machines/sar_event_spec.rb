require "rails_helper"

describe "state machine" do
  before(:all) do
    DbHousekeeping.clean
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

  after(:all) { DbHousekeeping.clean }

  describe :assign_to_new_team do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[disclosure_bmt sar_noff_awresp],
        %i[disclosure_bmt sar_noff_draft],
        %i[disclosure_bmt sar_noff_trig_awresp],
        %i[disclosure_bmt sar_noff_trig_awresp_accepted],
        %i[disclosure_bmt sar_noff_trig_draft],
        %i[disclosure_bmt sar_noff_trig_draft_accepted],
      ).with_transition_to(:awaiting_responder)
    }

    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[disclosure_bmt sar_noff_closed],
      ).with_transition_to(:closed)
    }
  end

  describe :update_closure do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[sar_responder sar_noff_closed],
        %i[another_sar_responder_in_same_team sar_noff_closed],
        %i[disclosure_bmt sar_noff_closed],
      )
    }
  end

  ############## EMAIL TESTS ################

  describe :add_message_to_case do
    it {
      expect(subject).to have_after_hook(
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

  describe :assign_responder do
    it {
      expect(subject).to have_after_hook(
        %i[disclosure_bmt sar_noff_unassigned],
      ).with_hook("Workflows::Hooks", :assign_responder_email)
    }
  end

  describe :assign_to_new_team do
    it {
      expect(subject).to have_after_hook(
        %i[disclosure_bmt sar_noff_awresp],
        %i[disclosure_bmt sar_noff_draft],
        %i[disclosure_bmt sar_noff_trig_awresp],
        %i[disclosure_bmt sar_noff_trig_awresp_accepted],
        %i[disclosure_bmt sar_noff_trig_draft],
        %i[disclosure_bmt sar_noff_trig_draft_accepted],
      ).with_hook("Workflows::Hooks", :assign_responder_email)
    }
  end

  describe :close do
    it {
      expect(subject).to have_after_hook(
        %i[sar_responder sar_noff_draft],
        %i[sar_responder sar_noff_trig_awdis],
        %i[another_sar_responder_in_same_team sar_noff_draft],
        %i[another_sar_responder_in_same_team sar_noff_trig_awdis],
      ).with_hook("Workflows::Hooks", :notify_managing_team_case_closed)
    }
  end

  describe :reassign_user do
    it {
      expect(subject).to have_after_hook(
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

  describe :progress_for_clearance do
    it {
      expect(subject).to have_after_hook(
        %i[sar_responder sar_noff_trig_draft_accepted],
        %i[sar_responder sar_noff_trig_draft],
        %i[another_sar_responder_in_same_team sar_noff_trig_draft_accepted],
        %i[another_sar_responder_in_same_team sar_noff_trig_draft],
      ).with_hook("Workflows::Hooks", :notify_approver_ready_for_review)
    }
  end

  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end
end
