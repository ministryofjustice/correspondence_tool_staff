require 'rails_helper'


describe 'Permitted Events' do

  let(:verbose)                             { true }
  let(:expected_results)                    { YAML.load_file(File.join(Rails.root, 'spec', 'lib', 'permitted_event_expected_results.yml')) }

  # teams
  let(:responding_team)                     { create :responding_team }

  # people
  let(:manager)                             { create :manager }
  let(:unassigned_responder)                { create :responder, responding_teams: [ responding_team ] }
  let(:assigned_responder)                  { create :responder, responding_teams: [ responding_team ] }

  # unflagged cases
  let(:unflagged_unassigned_case)           { create :case }
  let(:unflagged_awaiting_responder_case)   { create :awaiting_responder_case }
  let(:unflagged_drafting_case)             { create :case_being_drafted, responding_team: responding_team }

  # flagged cases
  let(:flagged_unassigned_case)             { create :case, :flagged }
  let(:flagged_awaiting_responder_case)     { create :awaiting_responder_case }




  # describe 'examine case' do
  #   it 'should be unassigned yet flagged for dacu' do
  #     ap responding_team
  #     ap unassigned_responder.teams
  #     # puts unflagged_awaiting_responder_case.current_state
  #     CasePrinter.new(unflagged_awaiting_responder_case).print
  #   end
  # end


  describe 'permitted events for different user types and case types' do
    it 'checks permitted events in yaml file match that produced in reality' do
      expected_results.each do |expected_result|
        user_type, case_type, events = expected_result
        user = __send__(user_type)
        kase = __send__(case_type)
        puts "Expecting user type #{user_type} with case type #{case_type} to have events: #{events.inspect}" if verbose
        expect(kase.state_machine.permitted_events(user.id)).to eq events
      end
    end

  end

end
