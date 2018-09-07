require 'rails_helper'

describe 'state machine' do

  before(:all) do
    DbHousekeeping.clean
    @setup = StandardSetup.new(
      only_cases: [
        :ot_ico_sar_noff_unassigned,
        :ot_ico_sar_noff_awresp,
        :ot_ico_sar_noff_draft,
        :ot_ico_sar_noff_trig_awresp,
        :ot_ico_sar_noff_trig_awresp_accepted,
        :ot_ico_sar_noff_trig_draft,
        :ot_ico_sar_noff_trig_draft_accepted,
      ]
    )
  end


  after(:all) { DbHousekeeping.clean }

  describe :assign_to_new_team do
    it { should permit_event_to_be_triggered_only_by(
                  [:disclosure_bmt, :ot_ico_sar_noff_awresp],
                  [:disclosure_bmt, :ot_ico_sar_noff_draft],
                  [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp],
                  [:disclosure_bmt, :ot_ico_sar_noff_trig_awresp_accepted],
                  [:disclosure_bmt, :ot_ico_sar_noff_trig_draft],
                  [:disclosure_bmt, :ot_ico_sar_noff_trig_draft_accepted],
                ).with_transition_to(:awaiting_responder) }

    # We haven't done closed ICO Overturned SAR cases yet. When we do,
    # re-instate this test.
    #
    # it { should permit_event_to_be_triggered_only_by(
    #               [:disclosure_bmt, :ot_ico_sar_noff_closed],
    #             ).with_transition_to(:closed) }
  end

  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end
end
