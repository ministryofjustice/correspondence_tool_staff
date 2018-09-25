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
        :ot_ico_sar_noff_closed
      ]
    )
  end


  after(:all) { DbHousekeeping.clean }

  describe :accept_responder_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
         [:responder, :ot_ico_sar_noff_awresp],
         [:another_responder_in_same_team, :ot_ico_sar_noff_awresp],
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

         [:responder, :ot_ico_sar_noff_awresp],
         [:responder, :ot_ico_sar_noff_draft],
         [:responder, :ot_ico_sar_noff_closed],

         [:another_responder_in_same_team, :ot_ico_sar_noff_awresp],
         [:another_responder_in_same_team, :ot_ico_sar_noff_draft],
         [:another_responder_in_same_team, :ot_ico_sar_noff_closed],

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
             )}
  end

  describe :close do
    it {
      should permit_event_to_be_triggered_only_by(
       [:responder, :ot_ico_sar_noff_draft],
       [:another_responder_in_same_team, :ot_ico_sar_noff_draft],

     )}
  end

  describe :destroy_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :ot_ico_sar_noff_unassigned],
        [:disclosure_bmt, :ot_ico_sar_noff_awresp],
        [:disclosure_bmt, :ot_ico_sar_noff_draft],
        [:disclosure_bmt, :ot_ico_sar_noff_closed],
      )}
  end

  describe :link_a_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :ot_ico_sar_noff_unassigned],
        [:disclosure_bmt, :ot_ico_sar_noff_awresp],
        [:disclosure_bmt, :ot_ico_sar_noff_draft],
        [:disclosure_bmt, :ot_ico_sar_noff_closed],
      )
    }
  end

  describe :reassign_user do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :ot_ico_sar_noff_draft],
        [:another_responder_in_same_team, :ot_ico_sar_noff_draft],
    )  }
  end

  describe :reject_responder_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :ot_ico_sar_noff_awresp],
        [:another_responder_in_same_team, :ot_ico_sar_noff_awresp],
  )  }
  end

  describe :remove_linked_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :ot_ico_sar_noff_unassigned],
        [:disclosure_bmt, :ot_ico_sar_noff_awresp],
        [:disclosure_bmt, :ot_ico_sar_noff_draft],
        [:disclosure_bmt, :ot_ico_sar_noff_closed],
     )    }
  end

  describe :respond do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :ot_ico_sar_noff_draft],
        [:another_responder_in_same_team, :ot_ico_sar_noff_draft],
      )}
  end

  describe :respond_and_close do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :ot_ico_sar_noff_draft],
        [:another_responder_in_same_team, :ot_ico_sar_noff_draft],
      )}
  end

  describe :update_closure do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :ot_ico_sar_noff_closed],
        [:responder, :ot_ico_sar_noff_closed],
        [:another_responder_in_same_team, :ot_ico_sar_noff_closed],
      )}
  end
end
