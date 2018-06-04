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
      ]
    )
  end


  after(:all) { DbHousekeeping.clean }

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
