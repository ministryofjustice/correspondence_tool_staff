require 'rails_helper'
require_relative '../../support/standard_setup.rb'

module Workflows

  describe 'state machine events' do

    before(:all) do
      @setup = StandardSetup.new
    end

    after(:all) { DbHousekeeping.clean }

    describe 'standard setup states' do
      it 'returns expected state' do
        expect(@setup.std_unassigned_case.current_state).to eq 'unassigned'
        expect(@setup.std_drafting_case.current_state).to eq 'drafting'
        expect(@setup.std_awdis_case.current_state).to eq 'awaiting_dispatch'
        expect(@setup.std_responded_case.current_state).to eq 'responded'
        expect(@setup.std_closed_case.current_state).to eq 'closed'
      end
    end

    describe 'standard setup workflows' do
      it 'returns expected workflows' do
        expect(@setup.std_unassigned_case.workflow).to eq 'standard'
        expect(@setup.std_drafting_case.workflow).to eq 'standard'
        expect(@setup.std_awdis_case.workflow).to eq 'standard'
        expect(@setup.std_responded_case.workflow).to eq 'standard'
        expect(@setup.std_closed_case.workflow).to eq 'standard'
      end
    end

  end

end
