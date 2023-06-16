require "rails_helper"

describe "state machine" do
  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end

  before(:all) do
    DbHousekeeping.clean
    @setup = StandardSetup.new(
      only_cases: %i[
        ot_ico_sar_noff_unassigned
        ot_ico_sar_noff_awresp
        ot_ico_sar_noff_draft
        ot_ico_sar_noff_closed
        ot_ico_sar_noff_trig_awresp
        ot_ico_sar_noff_trig_awresp_accepted
        ot_ico_sar_noff_trig_draft
        ot_ico_sar_noff_trig_draft_accepted
        ot_ico_sar_noff_pdacu
        ot_ico_sar_noff_trig_awdisp
      ],
    )
  end

  after(:all) { DbHousekeeping.clean }

  describe :accept_responder_assignment do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[sar_responder ot_ico_sar_noff_awresp],
        %i[sar_responder ot_ico_sar_noff_trig_awresp],
        %i[sar_responder ot_ico_sar_noff_trig_awresp_accepted],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_awresp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awresp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awresp_accepted],
      )
    }
  end

  describe :add_message_to_case do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[disclosure_bmt ot_ico_sar_noff_unassigned],
        %i[disclosure_bmt ot_ico_sar_noff_awresp],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awresp],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awresp_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_draft],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_closed],
        %i[disclosure_bmt ot_ico_sar_noff_pdacu],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awdisp],
        %i[disclosure_specialist ot_ico_sar_noff_pdacu],
        %i[disclosure_specialist ot_ico_sar_noff_trig_awdisp],
        %i[disclosure_specialist ot_ico_sar_noff_trig_draft_accepted],
        %i[sar_responder ot_ico_sar_noff_awresp],
        %i[sar_responder ot_ico_sar_noff_trig_awresp],
        %i[sar_responder ot_ico_sar_noff_trig_awresp_accepted],
        %i[sar_responder ot_ico_sar_noff_draft],
        %i[sar_responder ot_ico_sar_noff_trig_draft],
        %i[sar_responder ot_ico_sar_noff_trig_draft_accepted],
        %i[sar_responder ot_ico_sar_noff_closed],
        %i[sar_responder ot_ico_sar_noff_pdacu],
        %i[sar_responder ot_ico_sar_noff_trig_awdisp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_awresp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awresp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awresp_accepted],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_draft_accepted],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_closed],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_pdacu],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awdisp],
      ).debug
    }
  end

  describe :assign_responder do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[disclosure_bmt ot_ico_sar_noff_unassigned],
      )
    }
  end

  describe :assign_to_new_team do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[disclosure_bmt ot_ico_sar_noff_awresp],
        %i[disclosure_bmt ot_ico_sar_noff_draft],
        %i[disclosure_bmt ot_ico_sar_noff_closed],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awresp],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awresp_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_pdacu],
      )
    }
  end

  describe :close do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[sar_responder ot_ico_sar_noff_draft],
        %i[sar_responder ot_ico_sar_noff_trig_awdisp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awdisp],
      )
    }
  end

  describe :destroy_case do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[disclosure_bmt ot_ico_sar_noff_unassigned],
        %i[disclosure_bmt ot_ico_sar_noff_awresp],
        %i[disclosure_bmt ot_ico_sar_noff_draft],
        %i[disclosure_bmt ot_ico_sar_noff_closed],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awresp],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awresp_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_pdacu],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awdisp],
      )
    }
  end

  describe :link_a_case do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[disclosure_bmt ot_ico_sar_noff_unassigned],
        %i[disclosure_bmt ot_ico_sar_noff_awresp],
        %i[disclosure_bmt ot_ico_sar_noff_draft],
        %i[disclosure_bmt ot_ico_sar_noff_closed],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awresp],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awresp_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_pdacu],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awdisp],
      )
    }
  end

  describe :progress_for_clearance do
    it {
      expect(subject).to have_after_hook(
        %i[sar_responder ot_ico_sar_noff_trig_draft_accepted],
        %i[sar_responder ot_ico_sar_noff_trig_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_draft_accepted],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_draft],
      ).with_hook("Workflows::Hooks", :notify_approver_ready_for_review)
    }
  end

  describe :reassign_user do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[sar_responder ot_ico_sar_noff_draft],
        %i[sar_responder ot_ico_sar_noff_trig_awdisp],
        %i[sar_responder ot_ico_sar_noff_trig_draft],
        %i[sar_responder ot_ico_sar_noff_trig_draft_accepted],
        %i[sar_responder ot_ico_sar_noff_pdacu],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_draft_accepted],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_pdacu],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awdisp],
        %i[disclosure_specialist ot_ico_sar_noff_trig_draft_accepted],
        %i[disclosure_specialist ot_ico_sar_noff_pdacu],
        %i[disclosure_specialist ot_ico_sar_noff_trig_awdisp],
        %i[disclosure_specialist_coworker ot_ico_sar_noff_trig_draft_accepted],
        %i[disclosure_specialist_coworker ot_ico_sar_noff_pdacu],
        %i[disclosure_specialist_coworker ot_ico_sar_noff_trig_awdisp],
      )
    }
  end

  describe :reject_responder_assignment do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[sar_responder ot_ico_sar_noff_awresp],
        %i[sar_responder ot_ico_sar_noff_trig_awresp],
        %i[sar_responder ot_ico_sar_noff_trig_awresp_accepted],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_awresp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awresp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awresp_accepted],
      )
    }
  end

  describe :remove_linked_case do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[disclosure_bmt ot_ico_sar_noff_unassigned],
        %i[disclosure_bmt ot_ico_sar_noff_awresp],
        %i[disclosure_bmt ot_ico_sar_noff_draft],
        %i[disclosure_bmt ot_ico_sar_noff_closed],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awresp],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awresp_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awdisp],
        %i[disclosure_bmt ot_ico_sar_noff_pdacu],
      )
    }
  end

  describe :respond do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[sar_responder ot_ico_sar_noff_draft],
        %i[sar_responder ot_ico_sar_noff_trig_awdisp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awdisp],
      )
    }
  end

  describe :respond_and_close do
    it {
      expect(subject).to permit_event_to_be_triggered_only_by(
        %i[sar_responder ot_ico_sar_noff_draft],
        %i[sar_responder ot_ico_sar_noff_trig_awdisp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awdisp],
      )
    }
  end

  ############## EMAIL TESTS ################

  describe :add_message_to_case do
    it {
      expect(subject).to have_after_hook(
        %i[disclosure_bmt ot_ico_sar_noff_draft],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_pdacu],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awdisp],
        %i[disclosure_specialist ot_ico_sar_noff_trig_draft_accepted],
        %i[disclosure_specialist ot_ico_sar_noff_pdacu],
        %i[disclosure_specialist ot_ico_sar_noff_trig_awdisp],
        %i[sar_responder ot_ico_sar_noff_draft],
        %i[sar_responder ot_ico_sar_noff_trig_draft],
        %i[sar_responder ot_ico_sar_noff_trig_draft_accepted],
        %i[sar_responder ot_ico_sar_noff_pdacu],
        %i[sar_responder ot_ico_sar_noff_trig_awdisp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_draft_accepted],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_pdacu],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awdisp],
      ).with_hook("Workflows::Hooks", :notify_responder_message_received)
    }
  end

  describe :assign_responder do
    it {
      expect(subject).to have_after_hook(
        %i[disclosure_bmt ot_ico_sar_noff_unassigned],
      ).with_hook("Workflows::Hooks", :assign_responder_email)
    }
  end

  describe :assign_to_new_team do
    it {
      expect(subject).to have_after_hook(
        %i[disclosure_bmt ot_ico_sar_noff_awresp],
        %i[disclosure_bmt ot_ico_sar_noff_draft],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awresp],
        %i[disclosure_bmt ot_ico_sar_noff_trig_awresp_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft],
        %i[disclosure_bmt ot_ico_sar_noff_trig_draft_accepted],
        %i[disclosure_bmt ot_ico_sar_noff_pdacu],
      ).with_hook("Workflows::Hooks", :assign_responder_email)
    }
  end

  describe :close do
    it {
      expect(subject).to have_after_hook(
        %i[sar_responder ot_ico_sar_noff_draft],
        %i[sar_responder ot_ico_sar_noff_trig_awdisp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awdisp],
      ).with_hook("Workflows::Hooks", :notify_managing_team_case_closed)
    }
  end

  describe :reassign_user do
    it {
      expect(subject).to have_after_hook(
        %i[disclosure_specialist ot_ico_sar_noff_trig_draft_accepted],
        %i[disclosure_specialist ot_ico_sar_noff_pdacu],
        %i[disclosure_specialist ot_ico_sar_noff_trig_awdisp],
        %i[disclosure_specialist_coworker ot_ico_sar_noff_trig_draft_accepted],
        %i[disclosure_specialist_coworker ot_ico_sar_noff_pdacu],
        %i[disclosure_specialist_coworker ot_ico_sar_noff_trig_awdisp],
        %i[sar_responder ot_ico_sar_noff_draft],
        %i[sar_responder ot_ico_sar_noff_trig_draft],
        %i[sar_responder ot_ico_sar_noff_trig_draft_accepted],
        %i[sar_responder ot_ico_sar_noff_pdacu],
        %i[sar_responder ot_ico_sar_noff_trig_awdisp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_draft_accepted],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_pdacu],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awdisp],
      ).with_hook("Workflows::Hooks", :reassign_user_email)
    }
  end
end
