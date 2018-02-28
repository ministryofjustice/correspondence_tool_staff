require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')


feature 'FOI case that does not require clearance' do
  include Features::Interactions
  include CaseDateManipulation

  given(:responder)             { create :responder }
  given(:responding_team)       { responder.responding_teams.first }
  given(:manager)               { create :manager, managing_teams: [ team_dacu_bmt ] }
  given(:disclosure_specialist) { create :disclosure_specialist }
  given!(:press_officer)        { create :press_officer }
  given(:press_office)          { press_officer.approving_team }
  given!(:private_officer)      { create :private_officer,
                                         full_name: Settings.private_office_default_user }
  given(:private_office)        { private_officer.approving_team }
  given!(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  given(:team_dacu_bmt)         { find_or_create :team_dacu }

  background(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario 'trigger case', js: true do
    # create and assign case
    #
    kase = create_and_assign_foi_case type: Case::FOI::Standard,
                                      user: manager,
                                      responding_team: responding_team,
                                      flag_for_disclosure: true
    kase.reload
    expect(kase.current_state).to eq 'awaiting_responder'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 2
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    t = kase.transitions.first
    expect(t.event).to eq 'flag_for_clearance'
    expect(t.to_state).to eq 'unassigned'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq team_dacu_bmt.id
    expect(t.acting_user_id).to eq manager.id
    expect(t.target_team_id).to eq team_dacu_disclosure.id
    expect(t.target_user_id).to be_nil

    t = kase.transitions.last
    expect(t.event).to eq 'assign_responder'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq team_dacu_bmt.id
    expect(t.acting_user_id).to eq manager.id
    expect(t.target_team_id).to eq responding_team.id
    expect(t.target_user_id).to be_nil

    # take on case by disclosure
    # - unaccept
    # - re-accept
    # - take on.
    #
    take_case_on kase: kase,
                 user: disclosure_specialist,
                 test_undo: true
    kase.reload
    expect(kase.current_state).to eq 'awaiting_responder'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 5
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    transitions = kase.transitions
    t = transitions[2]
    expect(t.event).to eq 'accept_approver_assignment'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq team_dacu_disclosure.id
    expect(t.acting_user_id).to eq disclosure_specialist.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil


    t = transitions[3]
    expect(t.event).to eq 'unaccept_approver_assignment'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'standard'
    expect(t.acting_team_id).to eq team_dacu_disclosure.id
    expect(t.acting_user_id).to eq disclosure_specialist.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil

    t = transitions[4]
    expect(t.event).to eq 'accept_approver_assignment'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq team_dacu_disclosure.id
    expect(t.acting_user_id).to eq disclosure_specialist.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil

    # take on case by press office - which will do same for press
    # - unaccept
    # - re-accept
    # - take on.
    #

    take_case_on kase: kase,
                 user: press_officer,
                 test_undo: true
    kase.reload
    expect(kase.current_state).to eq 'awaiting_responder'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 11
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    transitions = kase.transitions.order(:sort_key)
    t = transitions[5]
    expect(t.event).to eq 'take_on_for_approval'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq press_office.id
    expect(t.acting_user_id).to eq press_officer.id
    expect(t.target_team_id).to eq press_office.id
    expect(t.target_user_id).to be_nil

    t = transitions[6]
    expect(t.event).to eq 'take_on_for_approval'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq press_office.id
    expect(t.acting_user_id).to eq private_officer.id       # this is a bit wrong!
    expect(t.target_team_id).to eq private_office.id
    expect(t.target_user_id).to be_nil

    t = transitions[7]
    expect(t.event).to eq 'unflag_for_clearance'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'standard'                  # this is wrong - we don't want to change workflows when press unflags for clearance
    expect(t.acting_team_id).to eq press_office.id
    expect(t.acting_user_id).to eq press_officer.id
    expect(t.target_team_id).to eq private_office.id
    expect(t.target_user_id).to be_nil

    t = transitions[8]
    expect(t.event).to eq 'unflag_for_clearance'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'standard'
    expect(t.acting_team_id).to eq press_office.id
    expect(t.acting_user_id).to eq press_officer.id
    expect(t.target_team_id).to eq press_office.id
    expect(t.target_user_id).to be_nil

    t = transitions[9]
    expect(t.event).to eq 'take_on_for_approval'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq press_office.id
    expect(t.acting_user_id).to eq press_officer.id
    expect(t.target_team_id).to eq press_office.id
    expect(t.target_user_id).to be_nil

    t = transitions[10]
    expect(t.event).to eq 'take_on_for_approval'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq press_office.id
    expect(t.acting_user_id).to eq private_officer.id
    expect(t.target_team_id).to eq private_office.id
    expect(t.target_user_id).to be_nil

    # case manager edits case
    edit_case kase: kase,
              user: manager,
              subject: 'new test subject'

    kase.reload
    expect(kase.current_state).to eq 'awaiting_responder'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 12
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    t = kase.transitions.last
    expect(t.event).to eq 'edit_case'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq team_dacu_bmt.id
    expect(t.acting_user_id).to eq manager.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil


    # responder accepts case
    #
    accept_case kase: kase,
                user: responder,
                do_logout: false

    kase.reload
    expect(kase.current_state).to eq 'drafting'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 13
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    t = kase.transitions.last
    expect(t.event).to eq 'accept_responder_assignment'
    expect(t.to_state).to eq 'drafting'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq responding_team.id
    expect(t.acting_user_id).to eq responder.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil

    # responder adds a message to the case
    #
    set_case_dates_back_by(kase, 5.business_days)
    add_message_to_case kase: kase, message: 'This. Is. A. Test.'

    kase.reload
    expect(kase.current_state).to eq 'drafting'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 14
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    t = kase.transitions.last
    expect(t.event).to eq 'add_message_to_case'
    expect(t.to_state).to eq 'drafting'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq responding_team.id
    expect(t.acting_user_id).to eq responder.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil
    expect(t.message).to eq 'This. Is. A. Test.'

    # disclosure specialist extends for PIT
    #
    extend_for_pit kase: kase,
                   user: disclosure_specialist,
                   new_deadline: 30.business_days.from_now

    expect(kase.current_state).to eq 'drafting'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 15
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    t = kase.transitions.last
    expect(t.event).to eq 'extend_for_pit'
    expect(t.to_state).to eq 'drafting'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq team_dacu_disclosure.id
    expect(t.acting_user_id).to eq disclosure_specialist.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil
    expect(t.message).to match(/Extending to \d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d \+\d\d\d\d for testing/)

    # responder uploads response
    #
    upload_response kase: kase,
    user: responder,
        file: UPLOAD_RESPONSE_DOCX_FIXTURE

    expect(kase.current_state).to eq 'pending_dacu_clearance'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 16
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    t = kase.transitions.last
    expect(t.event).to eq 'add_response_to_flagged_case'
    expect(t.to_state).to eq 'pending_dacu_clearance'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq responding_team.id
    expect(t.acting_user_id).to eq responder.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil

    # disclosure specialist clears response
    #
    clear_response kase: kase,
                   user: disclosure_specialist,
                   expected_team: press_office,
                   expected_status: 'Pending clearance'

    kase.reload
    expect(kase.current_state).to eq 'pending_press_office_clearance'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 17
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    t = kase.transitions.last
    expect(t.event).to eq 'approve'
    expect(t.to_state).to eq 'pending_press_office_clearance'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq team_dacu_disclosure.id
    expect(t.acting_user_id).to eq disclosure_specialist.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil


    # press office clears response
    #
    clear_response kase: kase,
                   user: press_officer,
                   expected_team: private_office,
                   expected_status: 'Pending clearance'

    kase.reload
    expect(kase.current_state).to eq 'pending_private_office_clearance'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 18
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    t = kase.transitions.last
    expect(t.event).to eq 'approve'
    expect(t.to_state).to eq 'pending_private_office_clearance'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq press_office.id
    expect(t.acting_user_id).to eq press_officer.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil

    # private office clears response
    #
    clear_response kase: kase,
                   user: private_officer,
                   expected_team: responding_team,
                   expected_status: 'Ready to send'

    kase.reload
    expect(kase.current_state).to eq 'awaiting_dispatch'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 19
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    t = kase.transitions.last
    expect(t.event).to eq 'approve'
    expect(t.to_state).to eq 'awaiting_dispatch'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq private_office.id
    expect(t.acting_user_id).to eq private_officer.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil

    # responder marks case as response sent
    #
    mark_case_as_sent kase: kase,
                      user: responder

    kase.reload
    expect(kase.current_state).to eq 'responded'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 20
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    t = kase.transitions.last
    expect(t.event).to eq 'respond'
    expect(t.to_state).to eq 'responded'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq responding_team.id
    expect(t.acting_user_id).to eq responder.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil

    # case manager closes case
    #
    close_case kase: kase,
               user: manager

    kase.reload
    expect(kase.current_state).to eq 'closed'
    expect(kase.workflow).to eq 'trigger'
    expect(kase.transitions.size).to eq 21
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    t = kase.transitions.last
    expect(t.event).to eq 'close'
    expect(t.to_state).to eq 'closed'
    expect(t.to_workflow).to eq 'trigger'
    expect(t.acting_team_id).to eq team_dacu_bmt.id
    expect(t.acting_user_id).to eq manager.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil
  end

  scenario 'non trigger case', js: true do
    # create and assign case
    #
    kase = create_and_assign_foi_case type: Case::FOI::Standard,
                                      user: manager,
                                      responding_team: responding_team

    kase.reload
    expect(kase.current_state).to eq 'awaiting_responder'
    expect(kase.workflow).to eq 'standard'
    expect(kase.transitions.size).to eq 1
    expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)

    t = kase.transitions.last
    expect(t.event).to eq 'assign_responder'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'standard'
    expect(t.acting_team_id).to eq team_dacu_bmt.id
    expect(t.acting_user_id).to eq manager.id
    expect(t.target_team_id).to eq responding_team.id
    expect(t.target_user_id).to be_nil


    # case manager edits case
    #
    edit_case kase: kase,
              user: manager,
              subject: 'new test subject'

    kase.reload
    expect(kase.current_state).to eq 'awaiting_responder'
    expect(kase.workflow).to eq 'standard'
    expect(kase.transitions.size).to eq 2
    expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)

    t = kase.transitions.last
    expect(t.event).to eq 'edit_case'
    expect(t.to_state).to eq 'awaiting_responder'
    expect(t.to_workflow).to eq 'standard'
    expect(t.acting_team_id).to eq team_dacu_bmt.id
    expect(t.acting_user_id).to eq manager.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil


    # responder accepts case
    #
    accept_case kase: kase,
                user: responder,
                do_logout: false

    kase.reload
    expect(kase.current_state).to eq 'drafting'
    expect(kase.workflow).to eq 'standard'
    expect(kase.transitions.size).to eq 3
    expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)

    t = kase.transitions.last
    expect(t.event).to eq 'accept_responder_assignment'
    expect(t.to_state).to eq 'drafting'
    expect(t.to_workflow).to eq 'standard'
    expect(t.acting_team_id).to eq responding_team.id
    expect(t.acting_user_id).to eq responder.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil

    set_case_dates_back_by(kase, 7.business_days)

    # responder adds a message to the case
    #
    add_message_to_case kase: kase,
                        message: 'This. Is. A. Test.',
                        do_logout: false

    kase.reload
    expect(kase.current_state).to eq 'drafting'
    expect(kase.workflow).to eq 'standard'
    expect(kase.transitions.size).to eq 4
    expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)

    t = kase.transitions.last
    expect(t.event).to eq 'add_message_to_case'
    expect(t.to_state).to eq 'drafting'
    expect(t.to_workflow).to eq 'standard'
    expect(t.acting_team_id).to eq responding_team.id
    expect(t.acting_user_id).to eq responder.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil
    expect(t.message).to eq 'This. Is. A. Test.'



    # responder uploads a response to the case
    #
    upload_response kase: kase,
                    user: responder,
                    file: UPLOAD_RESPONSE_DOCX_FIXTURE,
                    do_login: false

    kase.reload
    expect(kase.current_state).to eq 'awaiting_dispatch'
    expect(kase.workflow).to eq 'standard'
    expect(kase.transitions.size).to eq 5
    expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)

    t = kase.transitions.last
    expect(t.event).to eq 'add_responses'
    expect(t.to_state).to eq 'awaiting_dispatch'
    expect(t.to_workflow).to eq 'standard'
    expect(t.acting_team_id).to eq responding_team.id
    expect(t.acting_user_id).to eq responder.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil


    # responder marks case as sent
    #
    mark_case_as_sent kase: kase,
                      user: responder

    kase.reload
    expect(kase.current_state).to eq 'responded'
    expect(kase.workflow).to eq 'standard'
    expect(kase.transitions.size).to eq 6
    expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)

    t = kase.transitions.last
    expect(t.event).to eq 'respond'
    expect(t.to_state).to eq 'responded'
    expect(t.to_workflow).to eq 'standard'
    expect(t.acting_team_id).to eq responding_team.id
    expect(t.acting_user_id).to eq responder.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil


    # manager closes case
    #
    close_case kase: kase,
               user: manager

    kase.reload
    expect(kase.current_state).to eq 'closed'
    expect(kase.workflow).to eq 'standard'
    expect(kase.transitions.size).to eq 7
    expect(kase.state_machine).to be_instance_of(Case::FOI::StandardStateMachine)

    t = kase.transitions.last
    expect(t.event).to eq 'close'
    expect(t.to_state).to eq 'closed'
    expect(t.to_workflow).to eq 'standard'
    expect(t.acting_team_id).to eq team_dacu_bmt.id
    expect(t.acting_user_id).to eq manager.id
    expect(t.target_team_id).to be_nil
    expect(t.target_user_id).to be_nil
  end

end
