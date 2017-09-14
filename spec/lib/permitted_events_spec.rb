require 'rails_helper'


describe 'Permitted Events' do

  let(:verbose)                                   { false }
  let(:expected_results)                          { YAML.load_file(File.join(Rails.root, 'spec', 'lib', 'permitted_event_expected_results.yml')) }

  # teams
  let(:responding_team)                           { create :responding_team }
  let(:dacu_disclosure_team)                      { find_or_create :team_dacu_disclosure }
  let(:press_office)                              { find_or_create :team_press_office }
  let(:private_office)                            { find_or_create :team_private_office }

  # people
  let(:manager)                                   { create :manager }
  let(:unassigned_responder)                      { create :responder, responding_teams: [ responding_team ] }
  let(:assigned_responder)                        { create :responder, responding_teams: [ responding_team ] }
  let(:assigned_dacu_disclosure_specialist)       { create :disclosure_specialist }
  let(:unassigned_dacu_disclosure_specialist)     { create :disclosure_specialist }
  let(:unassigned_press_officer)                  { create :press_officer }
  let(:assigned_press_officer)                    { create :press_officer }
  let(:unassigned_private_officer)                { create :private_officer }
  let(:assigned_private_officer)                  { create :private_officer }

  # unflagged cases
  let(:unflagged_unassigned_case)                 { create :case }
  let(:unflagged_awaiting_responder_case)         { create :awaiting_responder_case }
  let(:unflagged_drafting_case)                   { create :case_being_drafted, responding_team: responding_team }
  let(:unflagged_case_with_response)              { create :case_with_response, responding_team: responding_team }
  let(:unflagged_case_within_escalation_period)   { create :awaiting_responder_case, received_date: 1.day.ago, created_at: 1.day.ago }
  let(:pending_press_clearance_case)              { create :pending_press_clearance_case, press_officer: assigned_press_officer }
  let(:pending_private_clearance_case)            { create :pending_private_clearance_case, private_officer: assigned_private_officer }

  # flagged cases
  let(:flagged_unassigned_case)                   { create :case, :flagged }
  let(:flagged_awaiting_responder_case)           { create :awaiting_responder_case }
  let(:accepted_pending_dacu_clearance_case)      { create :pending_dacu_clearance_case,
                                                       responding_team: responding_team,
                                                       approver: assigned_dacu_disclosure_specialist }
  let(:unaccepted_pending_dacu_clearance_case)    { create :unaccepted_pending_dacu_clearance_case,
                                                       responding_team: responding_team }
  #
  #
  #
  # describe 'examine case' do
  #   it 'should be unassigned yet flagged for dacu' do
  #     puts ">>>>>>>>>>>>>> case state: #{pending_private_clearance_case.current_state} #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
  #     puts ">>>>>>>>>>>>>> unassigned_private_officer press officer #{unassigned_private_officer.full_name} #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
  #     puts ">>>>>>>>>>>>>> assigned_private_officer press officer: #{assigned_private_officer.full_name} #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
  #     CasePrinter.new(pending_private_clearance_case).print
  #   end
  # end
  #

  describe 'permitted events for different user types and case types' do
    it 'checks permitted events in yaml file match that produced in reality' do
      last_user_type = nil
      expected_results.each do |expected_result|
        user_type, case_type, expected_events = expected_result
        user = __send__(user_type)
        kase = __send__(case_type)
        if verbose
          if last_user_type != user_type
            last_user_type = user_type
            puts "\n#{user_type}:".yellow
          end
          puts sprintf("    %-40s %s", case_type, expected_events.inspect).yellow
        end
        actual_events =  kase.state_machine.permitted_events(user.id)

        if actual_events != expected_events
          puts "ERROR: Unexpected events for user #{user_type} with case #{case_type}".red
          puts "       Expected: #{expected_events.inspect}".red
          puts "       Got       #{actual_events.inspect}".red
        end
        expect(actual_events).to eq expected_events
      end
    end

  end

end
