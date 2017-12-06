require 'rails_helper'

#rubocop:disable Metrics/ModuleLength
module ConfigurableStateMachine

  class TestCallbacks
    def initialize(kase:, metadata:)

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
                    if: 'Cases::FOIPolicy#can_add_message_to_case?'
                  },
                  assign_responder: {
                    transition_to: 'awaiting_responder'
                  },
                  destroy_case: nil,
                  edit_case: nil,
                  flag_for_clearance: nil,
                  unflag_for_clearance: {
                    if: 'Cases::FOIPolicy#can_unflag_for_clearance?',
                  }
                },
                drafting: {
                  add_message_to_case: {
                    if: 'Cases::FOIPolicy#can_add_message_to_case?',
                    before_transition: 'ConfigurableStateMachine::TestCallbacks#before_transition_meth',
                    after_transition: 'ConfigurableStateMachine::TestCallbacks#before_transition_meth',
                    switch_workflow: 'timeliness_appeal',
                    transition_to: 'ready_to_send'
                  },
                  add_response: nil
                }
              }
            },
            approver: {
              states: {
                unassigned: {
                  add_message_to_case: {
                    if: 'Cases::FOIPolicy#can_add_message_to_case?'
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
              policy = double Cases::FOIPolicy
              expect(policy).to receive(:can_add_message_to_case?).and_return(true)
              expect(Cases::FOIPolicy).to receive(:new).with(user: user, kase: kase).and_return(policy)
              expect(machine.permitted_events(user)).to eq %i{ add_message_to_case flag_for_press}
            end
          end

          context 'predicate returns false' do
            it 'returns just the one event' do
              policy = double Cases::FOIPolicy
              expect(policy).to receive(:can_add_message_to_case?).and_return(false)
              expect(Cases::FOIPolicy).to receive(:new).with(user: user, kase: kase).and_return(policy)
              expect(machine.permitted_events(user)).to eq %i{ flag_for_press}
            end
          end
        end

        context 'user has roles manager and approver' do
          let(:user)    { create :manager_approver }

          context 'predicate returns true' do
            it 'returns all events' do
              policy = double Cases::FOIPolicy
              expect(policy).to receive(:can_add_message_to_case?).exactly(2).and_return(true)
              expect(policy).to receive(:can_unflag_for_clearance?).and_return(true)
              expect(Cases::FOIPolicy).to receive(:new).with(user: user, kase: kase).exactly(3).and_return(policy)
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

      before(:each) { @policy = double Cases::FOIPolicy }

      context 'role provided as a string parameter' do
        context 'event can be triggered' do
          context 'triggered as a result of an predicate returning true' do
            it 'returns  true' do
              expect(Cases::FOIPolicy).to receive(:new).with(user: @manager, kase: @unassigned_case).and_return(@policy)
              expect(@policy).to receive(:can_add_message_to_case?).and_return(true)
              machine = Machine.new(config: config, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                                                event_name: :add_message_to_case,
                                                metadata: {acting_user: @manager},
                                                roles: 'manager')
                                              ).to be true
            end
          end

          context 'triggered as a result of no if present' do
            it 'returns true' do
              expect(Cases::FOIPolicy).not_to receive(:new)
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
              expect(Cases::FOIPolicy).to receive(:new).with(user: @manager, kase: @unassigned_case).and_return(@policy)
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
        expect(machine).to receive(:trigger_event).with(event: 'dummy_event', params: metadata)
        machine.dummy_event!(metadata)
      end

      it 'raises NoMethodError for methods not ending in a bang' do
        expect {
          machine.dummy_method
        }.to raise_error NoMethodError, /undefined method `dummy_method' for/
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
            }.to raise_error InvalidEventError, %(Invalid Event: 'link_a_case': case_id: #{kase.id}, user_id: #{user.id})
          end
        end

        context 'no config for the state in this user role' do
          it 'raises InvalidEventError' do
            allow(@unassigned_case).to receive(:current_state).and_return('pending_dacu_clearance')
            expect {
              machine.link_a_case!({acting_user: @manager, acting_team: @managing_team, linked_case_id: 33})
            }.to raise_error InvalidEventError, %(Invalid Event: 'link_a_case': case_id: #{kase.id}, user_id: #{@manager.id})
          end
        end
      end
    end
  end
end
#rubocop:enable Metrics/ModuleLength
