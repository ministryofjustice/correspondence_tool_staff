
require 'rails_helper'

# require_relative '../support/standard_setup.rb'

describe Case::FOI::StandardStateMachine do

  before(:all) do
    DbHousekeeping.clean
    @setup = StandardSetup.new
  end

  after(:all) { DbHousekeeping.clean }


  describe :accept_responder_assignment do
    it {
      expect(1).to eq 1
      should permit_event_to_be_triggered_only_by(
        [:responder, :responding_team, :std_awresp_foi],
        [:responder, :responding_team, :trig_awresp_foi],
        [:responder, :responding_team, :full_awresp_foi]
      )
    }
  end



  def all_users
    @setup.users
  end

  def all_teams
    @setup.teams
  end

  def all_cases
    @setup.cases
  end

end
