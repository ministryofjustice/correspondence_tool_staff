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

  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end
end
