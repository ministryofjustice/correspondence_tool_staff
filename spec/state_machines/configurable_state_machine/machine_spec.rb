require 'rails_helper'

#rubocop:disable Metrics/ModuleLength
module ConfigurableStateMachine

  class TestCallbacks
    def initialize(kase:, metadata:)

    end
  end

  class DummyConditional
    def initialize(kase:, user:)
      @kase = kase
      @user = user
    end

    def remove_response
      if @kase.subject == 'Testing conditionals'
        'drafting'
      else
        'unassigned'
      end
    end
  end

  describe Machine do

    let(:config)  do
      RecursiveOpenStruct.new(
        {
          initial_state: 'unassigned',
          user_roles: {
            manager: {
              states: {
                unassigned: {
                  add_message_to_case: {
                    if: 'Case::FOI::StandardPolicy#can_add_message_to_case?'
                  },
                  assign_responder: {
                    transition_to: 'awaiting_responder'
                  },
                  destroy_case: nil,
                  edit_case: nil,
                  flag_for_clearance: nil,
                  unflag_for_clearance: {
                    if: 'Case::FOI::StandardPolicy#can_unflag_for_clearance?',
                  }
                },
                drafting: {
                  add_message_to_case: {
                    if: 'Case::FOI::StandardPolicy#can_add_message_to_case?',
                    switch_workflow: 'trigger',
                    transition_to: 'ready_to_send',
                    after_transition: 'Workflows::Hooks#notify_responder_message_received'
                  },
                  add_response: nil
                },
                awaiting_dispatch: {
                  remove_response: {
                    transition_to_using: 'ConfigurableStateMachine::DummyConditional#remove_response'
                  }
                }
              }
            },
            approver: {
              states: {
                unassigned: {
                  add_message_to_case: {
                    if: 'Case::FOI::StandardPolicy#can_add_message_to_case?'
                  },
                  flag_for_press: {
                    transition_to: 'awaiting_press_clearance'
                  }
                }
              }
            }
          }
        })
    end

    let(:kase)        { create :case }
    let(:machine)     { Machine.new(config: config, kase: kase)}

    before(:all) do
      @managing_team      = create :managing_team
      @unassigned_case    = create :case
      @manager            = create :manager, managing_teams: [@managing_team]
      @approver           = create :approver
      @manager_approver   = create :manager_approver

    end

    after(:all)   { DbHousekeeping.clean }

    describe 'configurable?' do
      it 'returns true' do
        expect(machine.configurable?).to be true
      end
    end

    describe 'initial_state' do
      it 'returns unassigned' do
        expect(machine.initial_state).to eq 'unassigned'
      end
    end

    describe 'current_state' do
      context 'current_state on case is nil' do
        it 'returns unassigned' do
          expect(kase).to receive(:current_state).and_return nil
          expect(machine.current_state).to eq 'unassigned'
        end
      end
      context 'current_state on case is set' do
        it 'returns current_state of case' do
          expect(kase).to receive(:current_state).and_return 'drafting'
          expect(machine.current_state).to eq 'drafting'
        end
      end
    end

    describe 'permitted_events' do
      context 'case is unassigned' do
        context 'user has role approver' do
          let(:user)    { create :approver}

          context 'predicate returns true' do
            it 'returns both the events for a user' do
              policy = double Case::FOI::StandardPolicy
              expect(policy).to receive(:can_add_message_to_case?).and_return(true)
              expect(Case::FOI::StandardPolicy).to receive(:new).with(user: user, kase: kase).and_return(policy)
              expect(machine.permitted_events(user)).to eq %i{ add_message_to_case flag_for_press}
            end
          end

          context 'predicate returns false' do
            it 'returns just the one event' do
              policy = double Case::FOI::StandardPolicy
              expect(policy).to receive(:can_add_message_to_case?).and_return(false)
              expect(Case::FOI::StandardPolicy).to receive(:new).with(user: user, kase: kase).and_return(policy)
              expect(machine.permitted_events(user)).to eq %i{ flag_for_press}
            end
          end
        end

        context 'user has roles manager and approver' do
          let(:user)    { create :manager_approver }

          context 'predicate returns true' do
            it 'returns all events' do
              policy = double Case::FOI::StandardPolicy
              expect(policy).to receive(:can_add_message_to_case?).exactly(2).and_return(true)
              expect(policy).to receive(:can_unflag_for_clearance?).and_return(true)
              expect(Case::FOI::StandardPolicy).to receive(:new).with(user: user, kase: kase).exactly(3).and_return(policy)
              expect(machine.permitted_events(user)).to eq %i{
                                  add_message_to_case
                                  assign_responder
                                  destroy_case
                                  edit_case
                                  flag_for_clearance
                                  flag_for_press
                                  unflag_for_clearance
                                }
            end
          end
        end
      end
    end

    describe 'can_trigger_event' do

      before(:each) { @policy = double Case::FOI::StandardPolicy }

      context 'role provided as a string parameter' do
        context 'event can be triggered' do
          context 'triggered as a result of an predicate returning true' do
            it 'returns  true' do
              expect(Case::FOI::StandardPolicy).to receive(:new).with(user: @manager, kase: @unassigned_case).and_return(@policy)
              expect(@policy).to receive(:can_add_message_to_case?).and_return(true)
              machine = Machine.new(config: config, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                                                event_name: :add_message_to_case,
                                                metadata: {acting_user: @manager},
                                                roles: 'manager')
                                              ).to be true
            end
          end

          context 'triggered as a result of no "if present' do
            it 'returns true' do
              expect(Case::FOI::StandardPolicy).not_to receive(:new)
              config.user_roles.manager.states.unassigned.add_message_to_case.delete_field(:if)
              expect(machine.can_trigger_event?(
                                                event_name: :add_message_to_case,
                                                metadata: {acting_user: @manager},
                                                roles: 'manager')
                                              ).to be true

            end
          end
        end

        context 'event cannot be triggered' do
          context 'not triggered as a result of a predicate returning false' do
            it 'returns  false' do
              expect(Case::FOI::StandardPolicy).to receive(:new).with(user: @manager, kase: @unassigned_case).and_return(@policy)
              expect(@policy).to receive(:can_add_message_to_case?).and_return(false)
              machine = Machine.new(config: config, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                                                event_name: :add_message_to_case,
                                                metadata: {acting_user: @manager},
                                                roles: 'manager')
                                              ).to be false
            end
          end
          context 'event not a valid event for role/state' do
            it 'returns false' do
              machine = Machine.new(config: config, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                                                event_name: :flag_for_press,
                                                metadata: {acting_user: @manager},
                                                roles: 'manager')
                                              ).to be false
            end
          end
        end
      end

      context 'roles provided as a parameter as an array' do
        context 'event can be triggered because no predicate or other keys' do
          it 'returns true' do
            machine = Machine.new(config: config, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                                              event_name: :destroy_case,
                                              metadata: {acting_user: @manager},
                                              roles: ['manager'])
                                             ).to be true
          end
        end

        context 'event cannot be triggered' do
          context 'event is not listed for the role/state' do
            it 'returns false' do
              machine = Machine.new(config: config, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                                                event_name: :close_case,
                                                metadata: {acting_user: @manager},
                                                roles: ['manager'])
                                              ).to be false
            end
          end
        end
      end

      context 'team provided in metadata' do
        context 'event can be triggered' do
          it 'returns true' do
            machine = Machine.new(config: config, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                                              event_name: :destroy_case,
                                              metadata: {acting_user: @manager, acting_team: @managing_team })
                                            ).to be true
          end
        end

        context 'event cannot be triggered' do
          it 'returns false' do
            machine = Machine.new(config: config, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                                              event_name: :close_case,
                                              metadata: {acting_user: @manager, acting_team: @managing_team })
                                            ).to be false
          end
        end

      end
      context 'team_id provided in metadata' do
        context 'event can be triggered' do
          it 'returns true' do
            machine = Machine.new(config: config, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                                              event_name: :destroy_case,
                                              metadata: {acting_user: @manager, acting_team_id: @managing_team.id })
                                            ).to be true
          end
        end

        context 'event cannot be triggered' do
          it 'returns false' do
            machine = Machine.new(config: config, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                                              event_name: :close_case,
                                              metadata: {acting_user: @manager, acting_team_id: @managing_team.id })
                                            ).to be false
          end
        end
      end
      context 'only acting_user provided as param' do
        context 'user has one role' do
          context 'event can be triggered' do
            it 'returns true' do
              machine = Machine.new(config: config, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                                                event_name: :destroy_case,
                                                metadata: {acting_user: @manager})
                                              ).to be true
            end
          end
          context 'event cannot be triggered' do
            it 'returns false' do
              machine = Machine.new(config: config, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                                                event_name: :close_case,
                                                metadata: {acting_user: @manager })
                                              ).to be false
            end
          end

        end
        context 'user has two roles' do
          context 'event can be triggered by second of two roles' do
            it 'returns true' do
              machine = Machine.new(config: config, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                                                event_name: :flag_for_press,
                                                metadata: {acting_user: @manager_approver })
                                              ).to be true
            end
          end

          context 'event can be triggered by first of two roles' do
            it 'returns true' do
              machine = Machine.new(config: config, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                                                event_name: :flag_for_clearance,
                                                metadata: {acting_user: @manager_approver })
                                              ).to be true
            end
          end
        end
      end
      context 'only acting user_id provided as param' do
        context 'event can be triggered' do
          it 'returns true' do
            machine = Machine.new(config: config, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                                              event_name: :destroy_case,
                                              metadata: {acting_user_id: @manager.id})
                                            ).to be true
          end
        end
        context 'event cannot be triggered' do
          it 'returns false' do
            machine = Machine.new(config: config, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                                              event_name: :close_case,
                                              metadata: {acting_user_id: @manager.id})
                                            ).to be false
          end
        end
      end
    end

    describe '#method_missing' do
      it 'intercepts bang methods and triggers them as events' do
        user = double User
        team = double BusinessUnit
        metadata = { acting_user: user, acting_team: team }
        expect(machine).to receive(:trigger_event).with(event: :dummy_event, params: metadata)
        machine.dummy_event!(metadata)
      end

      it 'raises NoMethodError for methods not ending in a bang' do
        expect {
          machine.dummy_method
        }.to raise_error NoMethodError, /undefined method `dummy_method' for/
      end
    end


    context 'triggering events' do
      context 'switching workflow' do
        let(:kase)      { create :accepted_case }

        it 'updates the workflow on the case' do
          # given
          expect(kase.type_abbreviation).to eq 'FOI'
          expect(kase.current_state).to eq 'drafting'
          expect(kase.workflow).to eq 'standard'

          # when
          machine = Machine.new(config: config, kase: kase)
          machine.add_message_to_case!(
              message: 'NNNN',
              acting_team: @managing_team,
              acting_user: @manager)

          # then
          expect(kase.workflow).to eq 'trigger'
        end

        it 'writes the new workflow to the case transition' do
          # given
          expect(kase.current_state).to eq 'drafting'

          # when
          machine = Machine.new(config: config, kase: kase)
          machine.add_message_to_case!(
              message: 'This is my message to you all',
              acting_team: @managing_team,
              acting_user: @manager)

          # then
          transition = kase.transitions.last
          expect(transition.event).to eq 'add_message_to_case'
          expect(transition.to_state).to eq 'ready_to_send'
          expect(transition.to_workflow).to eq 'trigger'
          expect(transition.message).to eq 'This is my message to you all'
        end
      end

      context 'transition_to_using' do
        let(:kase)    { create :case_with_response }

        it 'updates the state on the case' do
          # given
          kase.subject = 'Testing conditionals'
          expect(kase.current_state).to eq 'awaiting_dispatch'
          expect(kase.workflow).to eq 'standard'

          # when
          machine = Machine.new(config: config, kase: kase)
          machine.remove_response!(
              acting_team: @managing_team,
              acting_user: @manager)

          # then
          expect(kase.current_state).to eq 'drafting'
        end

        it 'updates the to_state on the transition' do
          # given
          kase.subject = 'Testing conditionals'
          expect(kase.current_state).to eq 'awaiting_dispatch'
          expect(kase.workflow).to eq 'standard'

          # when
          machine = Machine.new(config: config, kase: kase)
          machine.remove_response!(
              acting_team: @managing_team,
              acting_user: @manager)

          # then
          transition = kase.reload.transitions.last
          expect(transition.event).to eq 'remove_response'
          expect(transition.to_state).to eq 'drafting'
        end

      end

      describe 'after_transition' do
        let(:kase)      { create :accepted_case }

        it 'calls the after transition predicate' do

          machine = Machine.new(config: config, kase: kase)
          service = double NotifyResponderService, call: :ok
          expect(NotifyResponderService).to receive(:new).with(kase, 'Message received').and_return(service)
          expect(service).to receive(:call)

          machine.add_message_to_case!(
              message: 'NNNN',
              acting_team: @managing_team,
              acting_user: @manager)
        end
      end
    end


    describe '#respond_to?' do
      context 'methods ending with a bang' do
        it 'returns true to respond_to? with a method ending in a bang' do
          expect(machine.respond_to?(:add_message!)).to be true
        end

        it 'returns true to a method defined on an ancestor' do
          expect(machine.respond_to?(:object_id)).to be true
        end

        it 'returns false to unrecognized methods' do
          expect(machine.respond_to?(:xxxxxxx)).to be false
        end
      end
    end

    describe '#method' do
      it 'returns a method object for a valid method' do
        method_object = machine.method(:add_message!)
        expect(method_object).to be_instance_of(Method)
      end

      it 'returns a method object for a valid method' do
        expect {
          machine.method(:xxxxxx)
        }.to raise_error NameError, %(undefined method `xxxxxx' for class `ConfigurableStateMachine::Machine')
      end
    end

    describe 'events' do
      context 'permitted_events not specially specified' do
        it 'returns a list of all events in alphabetical order' do
          expected_events = %i{
            add_message_to_case
            add_response
            assign_responder
            destroy_case
            edit_case
            flag_for_clearance
            flag_for_press
            remove_response
            unflag_for_clearance
          }
          expect(machine.events).to eq expected_events
        end
      end
      context ' permitted_events specifically specified' do
        it 'returns a list of all events in alphabetical order' do
          config.permitted_events =
          [:aaa, :bbb, :ccc]
          machine = Machine.new(config: config, kase: kase)
          expect(machine.events).to eq [:aaa, :bbb, :ccc]
        end
      end
    end



    describe '#trigger_event' do
      context 'invalid metadata' do
        context 'no acting user' do
          it 'raises' do
            expect {
              machine.dummy_event!({acting_team: 'abdb'})
            }.to raise_error ConfigurableStateMachine::ArgumentError, %(Invalid params when triggering dummy_event on case #{kase.id}: {:acting_team=>"abdb"})
          end
        end

        context 'no acting team' do
          it 'raises' do
            expect {
              machine.dummy_event!({acting_user: 'abdb'})
            }.to raise_error ConfigurableStateMachine::ArgumentError, %(Invalid params when triggering dummy_event on case #{kase.id}: {:acting_user=>"abdb"})
          end
        end
      end

      context 'valid metadata' do
        context 'no config for the user role' do
          it 'raises InvalidEventError' do
            team = create :responding_team
            user = team.users.first
            expect {
              machine.link_a_case!({acting_user: user, acting_team: team, linked_case_id: 33})
            }.to raise_error InvalidEventError do |error|
              expect(error.message).to match(/Invalid event: type: FOI/)
              expect(error.message).to match(/event: link_a_case/)
            end
          end
        end

        context 'no config for the state in this user role' do
          it 'raises InvalidEventError' do
            allow(@unassigned_case).to receive(:current_state).and_return('pending_dacu_clearance')
            expect {
              machine.link_a_case!({acting_user: @manager, acting_team: @managing_team, linked_case_id: 33})
            }.to raise_error InvalidEventError do |error|
              expect(error.message).to match(/Invalid event: type: FOI/)
              expect(error.message).to match(/event: link_a_case/)
            end
          end
        end

        context 'no event for this state' do
          it 'raises InvalidEventError' do
            expect {
                machine.non_existent_event!({acting_user: @manager, acting_team: @managing_team, linked_case_id: 33})
            }.to raise_error do |error|
              expect(error.message).to match(/Invalid event: type: FOI/)
              expect(error.message).to match(/event: non_existent_event/)
            end
          end
        end
      end
    end

    context 'private methods' do
      describe 'extract_roles_from_metadata' do


        let(:user)            { create :approver_responder_manager }
        let(:approving_team)  { user.approving_team }
        let(:responding_team) { user.responding_teams.first }
        let(:managing_team)   { user.managing_teams.first }
        let(:expected_roles)  { %w( approver manager responder ) }

        context 'acting_user no team' do
          it 'extracts all three roles' do
            metadata = { acting_user: user }
           expect(machine.__send__(:extract_roles_from_metadata, metadata)).to match_array expected_roles
          end
        end

        context 'acting_user_id no team' do
          it 'extracts all three roles' do
            metadata = { acting_user_id: user.id }
            expect(machine.__send__(:extract_roles_from_metadata, metadata)).to match_array expected_roles
          end
        end

        context 'acting_team_id' do
          it 'extracts the role for managing team' do
            metadata = { acting_user_id: user.id, acting_team_id: managing_team.id }
            expect(machine.__send__(:extract_roles_from_metadata, metadata)).to eq [ 'manager' ]
          end
        end

        context 'acting_team' do
          it 'extracts the role for approver' do
            metadata = { acting_user_id: user.id, acting_team: responding_team }
            expect(machine.__send__(:extract_roles_from_metadata, metadata)).to eq [ 'responder' ]
          end
        end
      end
    end
  end
end
#rubocop:enable Metrics/ModuleLength
