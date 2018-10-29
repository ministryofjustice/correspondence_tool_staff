require 'rails_helper'

describe 'state machine' do
  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end

  before(:all) do
    DbHousekeeping.clean
    @setup = StandardSetup.new(
      only_cases: [
        :ot_ico_sar_noff_unassigned,
        :ot_ico_sar_noff_awresp,
        :ot_ico_sar_noff_draft,
        :ot_ico_sar_noff_closed,
        :ot_ico_sar_noff_trig_awresp,
        :ot_ico_sar_noff_trig_awresp_accepted,
        :ot_ico_sar_noff_trig_draft,
        :ot_ico_sar_noff_trig_draft_accepted,
        :ot_ico_sar_noff_pdacu,
        :ot_ico_sar_noff_trig_awdisp
      ]
    )
  end


  after(:all) { DbHousekeeping.clean }


  describe :accept_responder_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
         [:responder, :ot_ico_sar_noff_awresp],
         [:responder, :ot_ico_sar_noff_trig_awresp],
         [:responder, :ot_ico_sar_noff_trig_awresp_accepted],
         [:another_responder_in_same_team, :ot_ico_sar_noff_awresp],
         [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awresp],
         [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awresp_accepted],
       )
    }
  end

  describe :add_message_to_case do
    it {
      should permit_event_to_be_triggered_only_by(
         [:disclosure_bmt, :ot_ico_sar_noff_unassigned],
         [:disclosure_bmt, :ot_ico_sar_noff_awresp],
         [:disclosure_bmt, :ot_ico_sar_noff_draft],
         [:disclosure_bmt, :ot_ico_sar_noff_closed],
         [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp],
         [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp_accepted],
         [:disclosure_bmt, :ot_ico_sar_noff_trig_draft],
         [:disclosure_bmt, :ot_ico_sar_noff_trig_draft_accepted],
         [:disclosure_bmt, :ot_ico_sar_noff_pdacu],
         [:disclosure_bmt, :ot_ico_sar_noff_trig_awdisp],

         [:responder, :ot_ico_sar_noff_awresp],
         [:responder, :ot_ico_sar_noff_draft],
         [:responder, :ot_ico_sar_noff_closed],
         [:responder, :ot_ico_sar_noff_trig_awresp],
         [:responder, :ot_ico_sar_noff_trig_awresp_accepted],
         [:responder, :ot_ico_sar_noff_trig_draft],
         [:responder, :ot_ico_sar_noff_trig_draft_accepted],
         [:responder, :ot_ico_sar_noff_pdacu],
         [:responder, :ot_ico_sar_noff_trig_awdisp],

         [:another_responder_in_same_team, :ot_ico_sar_noff_awresp],
         [:another_responder_in_same_team, :ot_ico_sar_noff_draft],
         [:another_responder_in_same_team, :ot_ico_sar_noff_closed],
         [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awresp],
         [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awresp_accepted],
         [:another_responder_in_same_team, :ot_ico_sar_noff_trig_draft],
         [:another_responder_in_same_team, :ot_ico_sar_noff_trig_draft_accepted],
         [:another_responder_in_same_team, :ot_ico_sar_noff_pdacu],
         [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awdisp],
       )
    }
  end

  describe :assign_responder do
    it {
      should permit_event_to_be_triggered_only_by(
               [:disclosure_bmt, :ot_ico_sar_noff_unassigned],
             )}
  end

  describe :assign_to_new_team do
    it {
      should permit_event_to_be_triggered_only_by(
               [:disclosure_bmt, :ot_ico_sar_noff_awresp],
               [:disclosure_bmt, :ot_ico_sar_noff_draft],
               [:disclosure_bmt, :ot_ico_sar_noff_closed],
               [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp],
               [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp_accepted],
               [:disclosure_bmt, :ot_ico_sar_noff_trig_draft],
               [:disclosure_bmt, :ot_ico_sar_noff_trig_draft_accepted],
               [:disclosure_bmt, :ot_ico_sar_noff_pdacu]
             ) }
  end

  describe :close do
    it {
      should permit_event_to_be_triggered_only_by(
       [:responder, :ot_ico_sar_noff_draft],
       [:responder, :ot_ico_sar_noff_trig_awdisp],
       [:another_responder_in_same_team, :ot_ico_sar_noff_draft],
       [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awdisp],

     )}
  end

  describe :destroy_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :ot_ico_sar_noff_unassigned],
        [:disclosure_bmt, :ot_ico_sar_noff_awresp],
        [:disclosure_bmt, :ot_ico_sar_noff_draft],
        [:disclosure_bmt, :ot_ico_sar_noff_closed],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp_accepted],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_draft],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_draft_accepted],
        [:disclosure_bmt, :ot_ico_sar_noff_pdacu],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_awdisp],
      )}
  end

  describe :link_a_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :ot_ico_sar_noff_unassigned],
        [:disclosure_bmt, :ot_ico_sar_noff_awresp],
        [:disclosure_bmt, :ot_ico_sar_noff_draft],
        [:disclosure_bmt, :ot_ico_sar_noff_closed],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp_accepted],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_draft],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_draft_accepted],
        [:disclosure_bmt, :ot_ico_sar_noff_pdacu],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_awdisp],
      )
    }
  end

  describe :reassign_user do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :ot_ico_sar_noff_draft],
        [:responder, :ot_ico_sar_noff_trig_awdisp],

        [:another_responder_in_same_team, :ot_ico_sar_noff_draft],
        [:another_responder_in_same_team, :ot_ico_sar_noff_trig_draft],
        [:another_responder_in_same_team, :ot_ico_sar_noff_trig_draft_accepted],
        [:another_responder_in_same_team, :ot_ico_sar_noff_pdacu],
        [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awdisp],

        [:disclosure_specialist, :ot_ico_sar_noff_trig_draft_accepted],
        [:disclosure_specialist, :ot_ico_sar_noff_pdacu],
        [:disclosure_specialist, :ot_ico_sar_noff_trig_awdisp],

        [:disclosure_specialist_coworker, :ot_ico_sar_noff_trig_draft_accepted],
        [:disclosure_specialist_coworker, :ot_ico_sar_noff_pdacu],
        [:disclosure_specialist_coworker, :ot_ico_sar_noff_trig_awdisp],

        [:responder, :ot_ico_sar_noff_trig_draft],
        [:responder, :ot_ico_sar_noff_trig_draft_accepted],
        [:responder, :ot_ico_sar_noff_pdacu],



      )
    }
  end

  describe :reject_responder_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :ot_ico_sar_noff_awresp],
        [:responder, :ot_ico_sar_noff_trig_awresp],
        [:responder, :ot_ico_sar_noff_trig_awresp_accepted],
        [:another_responder_in_same_team, :ot_ico_sar_noff_awresp],
        [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awresp],
        [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awresp_accepted],
  )  }
  end

  describe :remove_linked_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :ot_ico_sar_noff_unassigned],
        [:disclosure_bmt, :ot_ico_sar_noff_awresp],
        [:disclosure_bmt, :ot_ico_sar_noff_draft],
        [:disclosure_bmt, :ot_ico_sar_noff_closed],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp_accepted],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_draft],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_draft_accepted],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_awdisp],
        [:disclosure_bmt, :ot_ico_sar_noff_pdacu],
     )    }
  end

  describe :respond do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :ot_ico_sar_noff_draft],
        [:responder, :ot_ico_sar_noff_trig_awdisp],
        [:another_responder_in_same_team, :ot_ico_sar_noff_draft],
        [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awdisp],
      )}
  end

  describe :respond_and_close do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :ot_ico_sar_noff_draft],
        [:responder, :ot_ico_sar_noff_trig_awdisp],
        [:another_responder_in_same_team, :ot_ico_sar_noff_draft],
        [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awdisp],
      )}
  end

############## EMAIL TESTS ################

  describe :add_message_to_case do
    it {
      should have_after_hook(
         [:disclosure_bmt, :ot_ico_sar_noff_draft],
         [:disclosure_bmt, :ot_ico_sar_noff_trig_draft],
         [:disclosure_bmt, :ot_ico_sar_noff_trig_draft_accepted],
         [:disclosure_bmt, :ot_ico_sar_noff_pdacu],
         [:disclosure_bmt, :ot_ico_sar_noff_trig_awdisp],

         [:responder, :ot_ico_sar_noff_draft],
         [:responder, :ot_ico_sar_noff_trig_draft],
         [:responder, :ot_ico_sar_noff_trig_draft_accepted],
         [:responder, :ot_ico_sar_noff_pdacu],
         [:responder, :ot_ico_sar_noff_trig_awdisp],

         [:another_responder_in_same_team, :ot_ico_sar_noff_draft],
         [:another_responder_in_same_team, :ot_ico_sar_noff_trig_draft],
         [:another_responder_in_same_team, :ot_ico_sar_noff_trig_draft_accepted],
         [:another_responder_in_same_team, :ot_ico_sar_noff_pdacu],
         [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awdisp],
       ).with_hook('Workflows::Hooks', :notify_responder_message_received)
    }
  end

  describe :assign_responder do
    it {
      should have_after_hook(
        [:disclosure_bmt, :ot_ico_sar_noff_unassigned],
     ).with_hook('Workflows::Hooks', :assign_responder_email)
    }
  end


  describe :assign_to_new_team do
    it {
      should have_after_hook(
        [:disclosure_bmt, :ot_ico_sar_noff_awresp],
        [:disclosure_bmt, :ot_ico_sar_noff_draft],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp_accepted],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_draft],
        [:disclosure_bmt, :ot_ico_sar_noff_trig_draft_accepted],
        [:disclosure_bmt, :ot_ico_sar_noff_pdacu]
     ).with_hook('Workflows::Hooks', :assign_responder_email)
    }
  end

  describe :close do
    it {
      should have_after_hook(
       [:responder, :ot_ico_sar_noff_draft],
       [:responder, :ot_ico_sar_noff_trig_awdisp],

       [:another_responder_in_same_team, :ot_ico_sar_noff_draft],
       [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awdisp],
     ).with_hook('Workflows::Hooks', :notify_managing_team_case_closed)
    }
  end

  describe :reassign_user do
    it {
      should have_after_hook(
        [:disclosure_specialist, :ot_ico_sar_noff_trig_draft_accepted],
        [:disclosure_specialist, :ot_ico_sar_noff_pdacu],
        [:disclosure_specialist, :ot_ico_sar_noff_trig_awdisp],

        [:disclosure_specialist_coworker, :ot_ico_sar_noff_trig_draft_accepted],
        [:disclosure_specialist_coworker, :ot_ico_sar_noff_pdacu],
        [:disclosure_specialist_coworker, :ot_ico_sar_noff_trig_awdisp],

        [:responder, :ot_ico_sar_noff_draft],
        [:responder, :ot_ico_sar_noff_trig_draft],
        [:responder, :ot_ico_sar_noff_trig_draft_accepted],
        [:responder, :ot_ico_sar_noff_pdacu],
        [:responder, :ot_ico_sar_noff_trig_awdisp],

        [:another_responder_in_same_team, :ot_ico_sar_noff_draft],
        [:another_responder_in_same_team, :ot_ico_sar_noff_trig_draft],
        [:another_responder_in_same_team, :ot_ico_sar_noff_trig_draft_accepted],
        [:another_responder_in_same_team, :ot_ico_sar_noff_pdacu],
        [:another_responder_in_same_team, :ot_ico_sar_noff_trig_awdisp],
       ).with_hook('Workflows::Hooks', :reassign_user_email)
    }
  end

end
