require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
module ConfigurableStateMachine
  class TestCallbacks
    def initialize(kase:, metadata:); end
  end

  class DummyConditional
    def initialize(kase:, user:)
      @kase = kase
      @user = user
    end

    def remove_response
      if @kase.subject == "Testing conditionals"
        "drafting"
      else
        "unassigned"
      end
    end
  end

  class DummyPredicate
    def initialize(user:, kase:)
      @user = user
      @kase = kase
    end

    def can_trigger_dummy_event_as_manager?
      false
    end

    def can_trigger_dummy_event_as_approver?
      false
    end

    def can_trigger_dummy_event_as_responder?
      false
    end
  end

  describe Machine do
    let(:config) do
      RecursiveOpenStruct.new(
        {
          initial_state: "unassigned",
          user_roles: {
            manager: {
              states: {
                unassigned: {
                  add_message_to_case: {
                    if: "Case::FOI::StandardPolicy#can_add_message_to_case?",
                  },
                  assign_responder: {
                    transition_to: "awaiting_responder",
                  },
                  destroy_case: nil,
                  dummy_event_controlled_by_predicate: {
                    if: "ConfigurableStateMachine::DummyPredicate#can_trigger_dummy_event_as_manager?",
                  },
                  edit_case: nil,
                  flag_for_clearance: nil,
                  unflag_for_clearance: {
                    if: "Case::FOI::StandardPolicy#unflag_for_clearance?",
                  },
                },
                drafting: {
                  add_message_to_case: {
                    if: "Case::FOI::StandardPolicy#can_add_message_to_case?",
                    switch_workflow: "trigger",
                    transition_to: "ready_to_send",
                    after_transition: "Workflows::Hooks#notify_responder_message_received",
                  },
                  reassign_responder: {
                    transition_to: "awaiting_responder",
                  },
                  add_response: nil,
                },
                awaiting_dispatch: {
                  remove_response: {
                    transition_to_using: "ConfigurableStateMachine::DummyConditional#remove_response",
                  },
                },
              },
            },
            approver: {
              states: {
                unassigned: {
                  add_message_to_case: {
                    if: "Case::FOI::StandardPolicy#can_add_message_to_case?",
                  },
                  dummy_event_controlled_by_predicate: {
                    if: "ConfigurableStateMachine::DummyPredicate#can_trigger_dummy_event_as_approver?",
                  },
                  flag_for_press: {
                    transition_to: "awaiting_press_clearance",
                    switch_workflow_using: "Workflows::Conditionals#unaccept_approver_assignment",
                  },
                },
              },
            },
            responder: {
              states: {
                unassigned: {
                  dummy_event_controlled_by_predicate: {
                    if: "ConfigurableStateMachine::DummyPredicate#can_trigger_dummy_event_as_responder?",
                  },
                },
                drafting: {
                  add_message_to_case: {
                    if: "Case::FOI::StandardPolicy#can_add_message_to_case?",
                    after_transition: "Workflows::Hooks#notify_responder_message_received",
                  },
                  reassign_team_member: nil,
                  add_response: nil,
                },
              },
            },
          },
        },
      )
    end

    let(:kase)        { create :case }
    let(:machine)     { described_class.new(config:, kase:) }

    before(:all) do
      @managing_team      = create :managing_team
      @unassigned_case    = create :case
      @accepted_case      = create :accepted_case, :flagged_accepted
      @accepted_case1     = create :accepted_case, :flagged_accepted
      @manager            = create :manager, managing_teams: [@managing_team]
      @approver           = create :approver
      @manager_approver   = create :manager_approver
      @responder          = find_or_create :foi_responder
      @responding_team    = create :responding_team
    end

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    describe "initial_state" do
      it "returns unassigned" do
        expect(machine.initial_state).to eq "unassigned"
      end
    end

    describe "current_state" do
      context "when current_state on case is nil" do
        it "returns unassigned" do
          expect(kase).to receive(:current_state).and_return nil
          expect(machine.current_state).to eq "unassigned"
        end
      end

      context "when current_state on case is set" do
        it "returns current_state of case" do
          expect(kase).to receive(:current_state).and_return "drafting"
          expect(machine.current_state).to eq "drafting"
        end
      end
    end

    describe "permitted_events" do
      context "when case is unassigned" do
        context "and user has role approver" do
          let(:user) { create :approver }

          context "and predicate returns true" do
            it "returns both the events for a user" do
              policy = double Case::FOI::StandardPolicy
              expect(policy).to receive(:can_add_message_to_case?).and_return(true)
              expect(Case::FOI::StandardPolicy).to receive(:new).with(user:, kase:).and_return(policy)
              expect(machine.permitted_events(user)).to eq %i[add_message_to_case flag_for_press]
            end
          end

          context "and predicate returns false" do
            it "returns just the one event" do
              policy = double Case::FOI::StandardPolicy
              expect(policy).to receive(:can_add_message_to_case?).and_return(false)
              expect(Case::FOI::StandardPolicy).to receive(:new).with(user:, kase:).and_return(policy)
              expect(machine.permitted_events(user)).to eq %i[flag_for_press]
            end
          end
        end

        context "and user has roles manager and approver" do
          let(:user) { create :manager_approver }

          context "and predicate returns true" do
            it "returns all events" do
              policy = double Case::FOI::StandardPolicy
              expect(policy).to receive(:can_add_message_to_case?).exactly(2).and_return(true)
              expect(policy).to receive(:unflag_for_clearance?).and_return(true)
              expect(Case::FOI::StandardPolicy).to receive(:new).with(user:, kase:).exactly(3).and_return(policy)
              expect(machine.permitted_events(user)).to eq %i[
                add_message_to_case
                assign_responder
                destroy_case
                edit_case
                flag_for_clearance
                flag_for_press
                unflag_for_clearance
              ]
            end
          end
        end
      end
    end

    describe "can_trigger_event?" do
      before { @policy = double Case::FOI::StandardPolicy }

      context "when user has multiple roles" do
        context "and no user roles have rights to trigger event" do
          it "returns false" do
            machine = described_class.new(config:, kase: @unassigned_case)
            expect(machine).to receive(:extract_roles_from_metadata).and_return(%w[manager responder approver])
            expect(machine.can_trigger_event?(
                     event_name: :dummy_event_controlled_by_predicate,
                     metadata: { acting_user: @manager, acting_team_id: @managing_team.id },
                   )).to be false
          end
        end

        context "and the first user role is prevented from triggering an event by a predicate, but subsequent ones are ok" do
          it "returns true" do
            machine = described_class.new(config:, kase: @unassigned_case)
            expect_any_instance_of(DummyPredicate).to receive(:can_trigger_dummy_event_as_approver?).and_return(true)
            expect(machine).to receive(:extract_roles_from_metadata).and_return(%w[manager responder approver])
            expect(machine.can_trigger_event?(
                     event_name: :dummy_event_controlled_by_predicate,
                     metadata: { acting_user: @manager, acting_team_id: @managing_team.id },
                   )).to be true
          end
        end

        context "and all user roles have rights to trigger event" do
          it "returns true" do
            machine = described_class.new(config:, kase: @unassigned_case)
            expect_any_instance_of(DummyPredicate).to receive(:can_trigger_dummy_event_as_manager?).and_return(true)
            expect_any_instance_of(DummyPredicate).to receive(:can_trigger_dummy_event_as_approver?).and_return(true)
            expect_any_instance_of(DummyPredicate).to receive(:can_trigger_dummy_event_as_responder?).and_return(true)
            expect(machine).to receive(:extract_roles_from_metadata).and_return(%w[manager responder approver])
            expect(machine.can_trigger_event?(
                     event_name: :dummy_event_controlled_by_predicate,
                     metadata: { acting_user: @manager, acting_team_id: @managing_team.id },
                   )).to be true
          end
        end
      end

      context "when role provided as a string parameter" do
        context "and event can be triggered" do
          context "and triggered as a result of an predicate returning true" do
            it "returns  true" do
              expect(Case::FOI::StandardPolicy).to receive(:new).with(user: @manager, kase: @unassigned_case).and_return(@policy)
              expect(@policy).to receive(:can_add_message_to_case?).and_return(true)
              machine = described_class.new(config:, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                       event_name: :add_message_to_case,
                       metadata: { acting_user: @manager },
                       roles: "manager",
                     )).to be true
            end
          end

          context 'and triggered as a result of no "if present' do
            it "returns true" do
              expect(Case::FOI::StandardPolicy).not_to receive(:new)
              config.user_roles.manager.states.unassigned.add_message_to_case.delete_field(:if)
              expect(machine.can_trigger_event?(
                       event_name: :add_message_to_case,
                       metadata: { acting_user: @manager },
                       roles: "manager",
                     )).to be true
            end
          end
        end

        context "and event cannot be triggered" do
          context "and not triggered as a result of a predicate returning false" do
            it "returns  false" do
              expect(Case::FOI::StandardPolicy).to receive(:new).with(user: @manager, kase: @unassigned_case).and_return(@policy)
              expect(@policy).to receive(:can_add_message_to_case?).and_return(false)
              machine = described_class.new(config:, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                       event_name: :add_message_to_case,
                       metadata: { acting_user: @manager },
                       roles: "manager",
                     )).to be false
            end
          end

          context "and event not a valid event for role/state" do
            it "returns false" do
              machine = described_class.new(config:, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                       event_name: :flag_for_press,
                       metadata: { acting_user: @manager },
                       roles: "manager",
                     )).to be false
            end
          end
        end
      end

      context "when roles provided as a parameter as an array" do
        context "and event can be triggered because no predicate or other keys" do
          it "returns true" do
            machine = described_class.new(config:, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                     event_name: :destroy_case,
                     metadata: { acting_user: @manager },
                     roles: %w[manager],
                   )).to be true
          end
        end

        context "and event cannot be triggered" do
          context "and event is not listed for the role/state" do
            it "returns false" do
              machine = described_class.new(config:, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                       event_name: :close_case,
                       metadata: { acting_user: @manager },
                       roles: %w[manager],
                     )).to be false
            end
          end
        end
      end

      context "when team provided in metadata" do
        context "and event can be triggered" do
          it "returns true" do
            machine = described_class.new(config:, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                     event_name: :destroy_case,
                     metadata: { acting_user: @manager, acting_team: @managing_team },
                   )).to be true
          end
        end

        context "and event cannot be triggered" do
          it "returns false" do
            machine = described_class.new(config:, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                     event_name: :close_case,
                     metadata: { acting_user: @manager, acting_team: @managing_team },
                   )).to be false
          end
        end
      end

      context "when team_id provided in metadata" do
        context "and event can be triggered" do
          it "returns true" do
            machine = described_class.new(config:, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                     event_name: :destroy_case,
                     metadata: { acting_user: @manager, acting_team_id: @managing_team.id },
                   )).to be true
          end
        end

        context "and event cannot be triggered" do
          it "returns false" do
            machine = described_class.new(config:, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                     event_name: :close_case,
                     metadata: { acting_user: @manager, acting_team_id: @managing_team.id },
                   )).to be false
          end
        end
      end

      context "when only acting_user provided as param" do
        context "and user has one role" do
          context "and event can be triggered" do
            it "returns true" do
              machine = described_class.new(config:, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                       event_name: :destroy_case,
                       metadata: { acting_user: @manager },
                     )).to be true
            end
          end

          context "and event cannot be triggered" do
            it "returns false" do
              machine = described_class.new(config:, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                       event_name: :close_case,
                       metadata: { acting_user: @manager },
                     )).to be false
            end
          end
        end

        context "and user has two roles" do
          context "and event can be triggered by second of two roles" do
            it "returns true" do
              machine = described_class.new(config:, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                       event_name: :flag_for_press,
                       metadata: { acting_user: @manager_approver },
                     )).to be true
            end
          end

          context "and event can be triggered by first of two roles" do
            it "returns true" do
              machine = described_class.new(config:, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                       event_name: :flag_for_clearance,
                       metadata: { acting_user: @manager_approver },
                     )).to be true
            end
          end
        end
      end

      context "when only acting user_id provided as param" do
        context "and event can be triggered" do
          it "returns true" do
            machine = described_class.new(config:, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                     event_name: :destroy_case,
                     metadata: { acting_user_id: @manager.id },
                   )).to be true
          end
        end

        context "and event cannot be triggered" do
          it "returns false" do
            machine = described_class.new(config:, kase: @unassigned_case)
            expect(machine.can_trigger_event?(
                     event_name: :close_case,
                     metadata: { acting_user_id: @manager.id },
                   )).to be false
          end
        end
      end
    end

    describe "teams_that_can_trigger_event_on_case" do
      before { @policy = double Case::FOI::StandardPolicy }

      context "when user has single role for the case" do
        it "return empty when user has no right for an event" do
          machine = described_class.new(config:, kase: @unassigned_case)
          expect(machine.teams_that_can_trigger_event_on_case(
                   event_name: :add_response,
                   user: @responder,
                 )).to eq []
        end

        it "return the team involved when user has right for an event" do
          machine = described_class.new(config:, kase: @accepted_case)
          expect(machine.teams_that_can_trigger_event_on_case(
                   event_name: :add_response,
                   user: @responder,
                 )).to eq [@accepted_case.responding_team]
        end

        it "return the active team when user has deactivate and active teams both for an event" do
          machine = described_class.new(config:, kase: @accepted_case1)

          active_team = @accepted_case1.responding_team

          deactivated_responding_team = add_deactivated_team_as_responder_of_the_case
          expect(@responder.teams_for_case(@accepted_case1))
            .to include deactivated_responding_team

          expect(machine.teams_that_can_trigger_event_on_case(
                   event_name: :add_response,
                   user: @responder,
                 )).to eq [active_team]
        end
      end

      def add_deactivated_team_as_responder_of_the_case
        deactivated_responding_team = create :responding_team, deleted_at: 1.month.ago, name: "[DEACTIVATE]"
        @responder.team_roles << TeamsUsersRole.new(team: deactivated_responding_team, role: "responder")
        create :assignment,
               case: @accepted_case1,
               team: deactivated_responding_team,
               state: "accepted",
               role: "responding",
               created_at: @accepted_case1.created_at
        deactivated_responding_team.reload
        @responder.reload
        @accepted_case1.reload
        deactivated_responding_team
      end

      context "and user has multi roles for the case" do
        it "return the team only involved for a particular event" do
          machine = described_class.new(config:, kase: @accepted_case)
          manager = @accepted_case.managing_team.users.first
          @accepted_case.approving_teams.first.user_roles << TeamsUsersRole.new(user_id: manager.id, role: "approver")
          @accepted_case.approving_teams.reload
          manager.reload
          expect(machine.teams_that_can_trigger_event_on_case(
                   event_name: :reassign_responder,
                   user: manager,
                 )).to eq [@accepted_case.managing_team]
        end

        it "return all the teams which have the right for a particular event " do
          machine = described_class.new(config:, kase: @accepted_case)
          manager = @accepted_case.managing_team.users.first
          responding_team = @accepted_case.responding_team
          responding_team.user_roles << TeamsUsersRole.new(user_id: manager.id, role: "approver")
          responding_team.reload
          manager.reload
          expect(machine.teams_that_can_trigger_event_on_case(
                   event_name: :reassign_team_member,
                   user: manager,
                 )).to match_array [responding_team]
          expect(machine.teams_that_can_trigger_event_on_case(
                   event_name: :add_response,
                   user: manager,
                 )).to match_array [@accepted_case.managing_team, responding_team]
        end
      end
    end

    describe "#method_missing" do
      it "intercepts bang methods and triggers them as events" do
        user = double User
        team = double BusinessUnit
        metadata = { acting_user: user, acting_team: team }
        expect(machine).to receive(:trigger_event).with(event: :dummy_event, params: metadata)
        machine.dummy_event!(metadata)
      end

      it "raises NoMethodError for methods not ending in a bang" do
        expect {
          machine.dummy_method
        }.to raise_error NoMethodError, /undefined method `dummy_method' for/
      end
    end

    describe "triggering events" do
      describe "switching workflow" do
        context "when unconditional switch" do
          let(:kase)      { create :accepted_case }

          it "updates the workflow on the case" do
            # given
            expect(kase.type_abbreviation).to eq "FOI"
            expect(kase.current_state).to eq "drafting"
            expect(kase.workflow).to eq "standard"

            # when
            machine = described_class.new(config:, kase:)
            machine.add_message_to_case!(
              message: "NNNN",
              acting_team: @managing_team,
              acting_user: @manager,
            )

            # then
            expect(kase.workflow).to eq "trigger"
          end

          it "writes the new workflow to the case transition" do
            # given
            expect(kase.current_state).to eq "drafting"

            # when
            machine = described_class.new(config:, kase:)
            machine.add_message_to_case!(
              message: "This is my message to you all",
              acting_team: @managing_team,
              acting_user: @manager,
            )

            # then
            transition = kase.transitions.last
            expect(transition.event).to eq "add_message_to_case"
            expect(transition.to_state).to eq "ready_to_send"
            expect(transition.to_workflow).to eq "trigger"
            expect(transition.message).to eq "This is my message to you all"
          end
        end

        context "when condition switch workflow using" do
          it "updates the workflow on the case" do
            kase = create :case
            approver = find_or_create :press_officer
            expect(kase.workflow).to eq "standard"

            allow_any_instance_of(Workflows::Conditionals).to receive(:unaccept_approver_assignment).and_return("trigger")
            machine = described_class.new(config:, kase:)
            machine.flag_for_press!(acting_user: approver, acting_team: approver.approving_team)
            expect(kase.workflow).to eq "trigger"
          end
        end
      end

      context "when transition_to_using" do
        let(:kase) { create :case_with_response }

        it "updates the state on the case" do
          # given
          kase.subject = "Testing conditionals"
          expect(kase.current_state).to eq "awaiting_dispatch"
          expect(kase.workflow).to eq "standard"

          # when
          machine = described_class.new(config:, kase:)
          machine.remove_response!(
            acting_team: @managing_team,
            acting_user: @manager,
          )

          # then
          expect(kase.current_state).to eq "drafting"
        end

        it "updates the to_state on the transition" do
          # given
          kase.subject = "Testing conditionals"
          expect(kase.current_state).to eq "awaiting_dispatch"
          expect(kase.workflow).to eq "standard"

          # when
          machine = described_class.new(config:, kase:)
          machine.remove_response!(
            acting_team: @managing_team,
            acting_user: @manager,
          )

          # then
          transition = kase.reload.transitions.last
          expect(transition.event).to eq "remove_response"
          expect(transition.to_state).to eq "drafting"
        end
      end

      describe "after_transition" do
        let(:kase) { create :accepted_case, responder: @responder }

        it "calls the after transition predicate" do
          machine = described_class.new(config:, kase:)
          service = double NotifyResponderService, call: :ok
          expect(NotifyResponderService).to receive(:new).with(kase, "Message received").and_return(service)
          expect(service).to receive(:call)

          machine.add_message_to_case!(
            message: "NNNN",
            acting_team: @managing_team,
            acting_user: @manager,
          )
        end

        it "does not call the after transition predicate if user is assigned responder" do
          machine = described_class.new(config:, kase:)

          machine.add_message_to_case!(
            message: "NNNN",
            acting_team: @responding_team,
            acting_user: @responder,
          )

          expect(NotifyResponderService).not_to receive(:new)
        end
      end
    end

    describe "#respond_to?" do
      context "when methods ending with a bang" do
        it "returns true to respond_to? with a method ending in a bang" do
          expect(machine.respond_to?(:add_message!)).to be true
        end

        it "returns true to a method defined on an ancestor" do
          expect(machine.respond_to?(:object_id)).to be true
        end

        it "returns false to unrecognized methods" do
          expect(machine.respond_to?(:xxxxxxx)).to be false
        end
      end
    end

    describe "#method" do
      it "returns a method object for a valid method" do
        method_object = machine.method(:add_message!)
        expect(method_object).to be_instance_of(Method)
      end

      it "raises an error for an invalid method" do
        expect {
          machine.method(:xxxxxx)
        }.to raise_error NameError, %(undefined method `xxxxxx' for class `ConfigurableStateMachine::Machine')
      end
    end

    describe "events" do
      context "when permitted_events not specially specified" do
        it "returns a list of all events in alphabetical order" do
          expected_events = %i[
            add_message_to_case
            add_response
            assign_responder
            destroy_case
            dummy_event_controlled_by_predicate
            edit_case
            flag_for_clearance
            flag_for_press
            reassign_responder
            reassign_team_member
            remove_response
            unflag_for_clearance
          ]
          expect(machine.events).to eq expected_events
        end
      end

      context "when permitted_events specifically specified" do
        it "returns a list of all events in alphabetical order" do
          config.permitted_events =
            %i[aaa bbb ccc]
          machine = described_class.new(config:, kase:)
          expect(machine.events).to eq %i[aaa bbb ccc]
        end
      end
    end

    describe "#config_for_event" do
      before { @policy = double Case::FOI::StandardPolicy }

      context "when role provided as a string parameter" do
        context "and event can be triggered" do
          context "and triggered as a result of an predicate returning true" do
            it "returns the event config" do
              expect(Case::FOI::StandardPolicy)
                  .to receive(:new)
                          .with(user: @manager, kase: @unassigned_case)
                          .and_return(@policy)
              expect(@policy).to receive(:can_add_message_to_case?).and_return(true)
              machine = described_class.new(config:, kase: @unassigned_case)
              expect(machine.config_for_event(
                event_name: :add_message_to_case,
                metadata: { acting_user: @manager },
                roles: "manager",
              ).to_h)
                  .to eq({ if: "Case::FOI::StandardPolicy#can_add_message_to_case?" })
            end
          end

          context 'and triggered as a result of no "if present' do
            it "returns true" do
              expect(Case::FOI::StandardPolicy).not_to receive(:new)
              config.user_roles.manager.states.unassigned.add_message_to_case.delete_field(:if)
              expect(machine.can_trigger_event?(
                       event_name: :add_message_to_case,
                       metadata: { acting_user: @manager },
                       roles: "manager",
                     )).to be true
            end
          end
        end

        context "and event cannot be triggered" do
          context "and not triggered as a result of a predicate returning false" do
            it "returns  false" do
              expect(Case::FOI::StandardPolicy).to receive(:new).with(user: @manager, kase: @unassigned_case).and_return(@policy)
              expect(@policy).to receive(:can_add_message_to_case?).and_return(false)
              machine = described_class.new(config:, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                       event_name: :add_message_to_case,
                       metadata: { acting_user: @manager },
                       roles: "manager",
                     )).to be false
            end
          end

          context "and event not a valid event for role/state" do
            it "returns false" do
              machine = described_class.new(config:, kase: @unassigned_case)
              expect(machine.can_trigger_event?(
                       event_name: :flag_for_press,
                       metadata: { acting_user: @manager },
                       roles: "manager",
                     )).to be false
            end
          end
        end
      end
    end

    describe "#trigger_event" do
      context "when invalid metadata" do
        context "and no acting user" do
          it "raises" do
            expect {
              machine.dummy_event!({ acting_team: "abdb" })
            }.to raise_error ConfigurableStateMachine::ArgumentError, %(Invalid params when triggering dummy_event on case #{kase.id}: {:acting_team=>"abdb"})
          end
        end

        context "and no acting team" do
          it "raises" do
            expect {
              machine.dummy_event!({ acting_user: "abdb" })
            }.to raise_error ConfigurableStateMachine::ArgumentError, %(Invalid params when triggering dummy_event on case #{kase.id}: {:acting_user=>"abdb"})
          end
        end
      end

      context "when valid metadata" do
        context "and no config for the user role" do
          it "raises InvalidEventError" do
            team = create :responding_team
            user = team.users.first
            expect {
              machine.link_a_case!({ acting_user: user, acting_team: team, linked_case_id: 33 })
            }.to(raise_error do |error|
              expect(error.message).to match(/Invalid event: type: FOI/)
              expect(error.message).to match(/event: link_a_case/)
            end)
          end
        end

        context "and no config for the state in this user role" do
          it "raises InvalidEventError" do
            allow(@unassigned_case).to receive(:current_state).and_return("pending_dacu_clearance")
            expect {
              machine.link_a_case!({ acting_user: @manager, acting_team: @managing_team, linked_case_id: 33 })
            }.to(raise_error do |error|
              expect(error.message).to match(/Invalid event: type: FOI/)
              expect(error.message).to match(/event: link_a_case/)
            end)
          end
        end

        context "and no event for this state" do
          it "raises InvalidEventError" do
            expect {
              machine.non_existent_event!({ acting_user: @manager, acting_team: @managing_team, linked_case_id: 33 })
            }.to(raise_error do |error|
              expect(error.message).to match(/Invalid event: type: FOI/)
              expect(error.message).to match(/event: non_existent_event/)
            end)
          end
        end
      end
    end

    describe "private methods" do
      describe "extract_roles_from_metadata" do
        let(:user)            { create :approver_responder_manager }
        let(:approving_team)  { user.approving_team }
        let(:responding_team) { user.responding_teams.first }
        let(:managing_team)   { user.managing_teams.first }
        let(:expected_roles)  { %w[approver manager responder] }

        context "when acting_user no team" do
          it "extracts all three roles" do
            metadata = { acting_user: user }
            expect(machine.__send__(:extract_roles_from_metadata, metadata)).to match_array expected_roles
          end
        end

        context "when acting_user_id no team" do
          it "extracts all three roles" do
            metadata = { acting_user_id: user.id }
            expect(machine.__send__(:extract_roles_from_metadata, metadata)).to match_array expected_roles
          end
        end

        context "when acting_team_id" do
          it "extracts the role for managing team" do
            metadata = { acting_user_id: user.id, acting_team_id: managing_team.id }
            expect(machine.__send__(:extract_roles_from_metadata, metadata)).to eq %w[manager]
          end
        end

        context "when acting_team" do
          it "extracts the role for approver" do
            metadata = { acting_user_id: user.id, acting_team: responding_team }
            expect(machine.__send__(:extract_roles_from_metadata, metadata)).to eq %w[responder]
          end
        end
      end
    end

    describe "#next_state_for_event" do
      describe "invalid event" do
        it "raises" do
          expect {
            machine.next_state_for_event(:dummy_event, acting_user_id: @manager.id)
          }.to raise_error ConfigurableStateMachine::InvalidEventError
        end
      end

      describe "transition_to" do
        it "return the transition_to state" do
          kase = create :accepted_case
          machine = described_class.new(config:, kase:)
          manager = kase.managing_team.users.first
          expect(kase.current_state).to eq "drafting"
          next_state = machine.next_state_for_event(:add_message_to_case, acting_user_id: manager.id)
          expect(next_state).to eq "ready_to_send"
        end
      end

      describe "transition_to_using" do
        let(:kase)    { create :case_with_response }
        let(:manager) { kase.managing_team.users.first }
        let(:machine) { described_class.new(config:, kase:) }

        describe "conditonal returns drafting" do
          it "returns the return value of conditonal" do
            allow_any_instance_of(ConfigurableStateMachine::DummyConditional).to receive(:remove_response).and_return("drafting")
            expect(kase.current_state).to eq "awaiting_dispatch"
            next_state = machine.next_state_for_event(:remove_response, acting_user_id: manager.id)
            expect(next_state).to eq "drafting"
          end
        end
      end

      describe "no transition specified" do
        let(:kase)    { create :case, managing_team: @managing_team }
        let(:manager) { kase.managing_team.users.first }
        let(:machine) { described_class.new(config:, kase:) }

        it "returns the current state of the case" do
          expect(kase.current_state).to eq "unassigned"
          next_state = machine.next_state_for_event(:add_message_to_case, acting_user_id: manager.id)
          expect(next_state).to eq "unassigned"
        end
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
