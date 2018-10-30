require 'rails_helper'

describe 'state machine' do

  before(:all) do
    DbHousekeeping.clean
    @setup = StandardSetup.new(
      only_cases: [
        :sar_noff_unassigned,
        :sar_noff_awresp,
        :sar_noff_draft,
        :sar_noff_closed,
        :sar_noff_trig_awdis,
        :sar_noff_trig_awresp,
        :sar_noff_trig_awresp_accepted,
        :sar_noff_trig_draft,
        :sar_noff_trig_draft_accepted,
      ]
    )
  end


  after(:all) { DbHousekeeping.clean }

  describe :assign_to_new_team do
    it { should permit_event_to_be_triggered_only_by(
                  [:disclosure_bmt, :sar_noff_awresp],
                  [:disclosure_bmt, :sar_noff_draft],
                  [:disclosure_bmt, :sar_noff_trig_awresp],
                  [:disclosure_bmt, :sar_noff_trig_awresp_accepted],
                  [:disclosure_bmt, :sar_noff_trig_draft],
                  [:disclosure_bmt, :sar_noff_trig_draft_accepted],
                ).with_transition_to(:awaiting_responder) }

    it { should permit_event_to_be_triggered_only_by(
                  [:disclosure_bmt, :sar_noff_closed],
                ).with_transition_to(:closed) }
  end

  describe :update_closure do
    it { should permit_event_to_be_triggered_only_by(
                  [:disclosure_bmt, :sar_noff_closed],
                )}
  end

  ############## EMAIL TESTS ################

  describe :add_message_to_case do
    it {
      should have_after_hook(
         [:disclosure_bmt, :sar_noff_draft],
         [:disclosure_bmt, :sar_noff_trig_draft],
         [:disclosure_bmt, :sar_noff_trig_draft_accepted],
         [:disclosure_bmt, :sar_noff_trig_awdis],
         [:responder, :sar_noff_draft],
         [:responder, :sar_noff_trig_draft],
         [:responder, :sar_noff_trig_draft_accepted],
         [:responder, :sar_noff_trig_awdis],
         [:another_responder_in_same_team, :sar_noff_draft],
         [:another_responder_in_same_team, :sar_noff_trig_draft],
         [:another_responder_in_same_team, :sar_noff_trig_draft_accepted],
         [:another_responder_in_same_team, :sar_noff_trig_awdis],
       ).with_hook('Workflows::Hooks', :notify_responder_message_received)
    }
  end

  describe :assign_responder do
    it {
      should have_after_hook(
        [:disclosure_bmt, :sar_noff_unassigned]
     ).with_hook('Workflows::Hooks', :assign_responder_email)
    }
  end


  describe :assign_to_new_team do
    it {
      should have_after_hook(
        [:disclosure_bmt, :sar_noff_awresp],
        [:disclosure_bmt, :sar_noff_draft],
        [:disclosure_bmt, :sar_noff_trig_awresp],
        [:disclosure_bmt, :sar_noff_trig_awresp_accepted],
        [:disclosure_bmt, :sar_noff_trig_draft],
        [:disclosure_bmt, :sar_noff_trig_draft_accepted],
     ).with_hook('Workflows::Hooks', :assign_responder_email)
    }
  end

  describe :close do
    it {
      should have_after_hook(
       [:responder, :sar_noff_draft],
       [:responder, :sar_noff_trig_awdis],
       [:another_responder_in_same_team, :sar_noff_draft],
       [:another_responder_in_same_team, :sar_noff_trig_awdis],

     ).with_hook('Workflows::Hooks', :notify_managing_team_case_closed)
    }
  end

  describe :reassign_user do
    it {
      should have_after_hook(
        [:disclosure_specialist, :sar_noff_trig_awdis],
        [:disclosure_specialist, :sar_noff_trig_awresp_accepted],
        [:disclosure_specialist, :sar_noff_trig_draft_accepted],

        [:disclosure_specialist_coworker, :sar_noff_trig_awdis],
        [:disclosure_specialist_coworker, :sar_noff_trig_awresp_accepted],
        [:disclosure_specialist_coworker, :sar_noff_trig_draft_accepted],

        [:responder, :sar_noff_draft],
        [:responder, :sar_noff_trig_awdis],
        [:responder, :sar_noff_trig_draft_accepted],
        [:responder, :sar_noff_trig_draft],

        [:another_responder_in_same_team, :sar_noff_draft],
        [:another_responder_in_same_team, :sar_noff_trig_awdis],
        [:another_responder_in_same_team, :sar_noff_trig_draft_accepted],
        [:another_responder_in_same_team, :sar_noff_trig_draft],


     ).with_hook('Workflows::Hooks', :reassign_user_email)
    }
  end

  describe :progress_for_clearance do
    it {
      should have_after_hook(
        [:responder, :sar_noff_trig_draft_accepted],
        [:responder, :sar_noff_trig_draft],

        [:another_responder_in_same_team, :sar_noff_trig_draft_accepted],
        [:another_responder_in_same_team, :sar_noff_trig_draft],

     ).with_hook('Workflows::Hooks', :notify_approver_ready_for_review)
    }
  end

  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end
end
