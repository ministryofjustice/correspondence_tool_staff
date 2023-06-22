require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe "state machine" do
  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end

  before(:all) do
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

  after(:all) do
    DbHousekeeping.clean(seed: false)
  end

  describe "accept_responder_assignment" do
    let(:event) { :accept_responder_assignment }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
        %i[sar_responder ot_ico_sar_noff_awresp],
        %i[sar_responder ot_ico_sar_noff_trig_awresp],
        %i[sar_responder ot_ico_sar_noff_trig_awresp_accepted],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_awresp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awresp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awresp_accepted],
      )
    }
  end

  describe "add_message_to_case" do
    let(:event) { :add_message_to_case }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
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
      )
    }

    it {
      expect(event).to have_after_hook(
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

  describe "assign_responder" do
    let(:event) { :assign_responder }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
        %i[disclosure_bmt ot_ico_sar_noff_unassigned],
      )
    }

    it {
      expect(event).to have_after_hook(
        %i[disclosure_bmt ot_ico_sar_noff_unassigned],
      ).with_hook("Workflows::Hooks", :assign_responder_email)
    }
  end

  describe "assign_to_new_team" do
    let(:event) { :assign_to_new_team }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
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

    it {
      expect(event).to have_after_hook(
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

  describe "close" do
    let(:event) { :close }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
        %i[sar_responder ot_ico_sar_noff_draft],
        %i[sar_responder ot_ico_sar_noff_trig_awdisp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awdisp],
      )
    }

    it {
      expect(event).to have_after_hook(
        %i[sar_responder ot_ico_sar_noff_draft],
        %i[sar_responder ot_ico_sar_noff_trig_awdisp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awdisp],
      ).with_hook("Workflows::Hooks", :notify_managing_team_case_closed)
    }
  end

  describe "destroy_case" do
    let(:event) { :destroy_case }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
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

  describe "link_a_case" do
    let(:event) { :link_a_case }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
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

  describe "progress_for_clearance" do
    let(:event) { :progress_for_clearance }

    it {
      expect(event).to have_after_hook(
        %i[sar_responder ot_ico_sar_noff_trig_draft_accepted],
        %i[sar_responder ot_ico_sar_noff_trig_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_draft_accepted],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_draft],
      ).with_hook("Workflows::Hooks", :notify_approver_ready_for_review)
    }
  end

  describe "reassign_user" do
    let(:event) { :reassign_user }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
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

    it {
      expect(event).to have_after_hook(
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

  describe "reject_responder_assignment" do
    let(:event) { :reject_responder_assignment }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
        %i[sar_responder ot_ico_sar_noff_awresp],
        %i[sar_responder ot_ico_sar_noff_trig_awresp],
        %i[sar_responder ot_ico_sar_noff_trig_awresp_accepted],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_awresp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awresp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awresp_accepted],
      )
    }
  end

  describe "remove_linked_case" do
    let(:event) { :remove_linked_case }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
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

  describe "respond" do
    let(:event) { :respond }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
        %i[sar_responder ot_ico_sar_noff_draft],
        %i[sar_responder ot_ico_sar_noff_trig_awdisp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awdisp],
      )
    }
  end

  describe "respond_and_close" do
    let(:event) { :respond_and_close }

    it {
      expect(event).to permit_event_to_be_triggered_only_by(
        %i[sar_responder ot_ico_sar_noff_draft],
        %i[sar_responder ot_ico_sar_noff_trig_awdisp],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_draft],
        %i[another_sar_responder_in_same_team ot_ico_sar_noff_trig_awdisp],
      )
    }
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
