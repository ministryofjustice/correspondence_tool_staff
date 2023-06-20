require "rails_helper"

module ConfigurableStateMachine
  class DummyPredicate
    def can_assign_responder?
      true
    end
  end

  describe "ConfigValidator" do
    let(:config) { RecursiveOpenStruct.new(config_as_hash) }
    let(:config_as_hash) do
      {
        preamble: {
          organisation: "Ministry of Justice",
          organisation_abbreviation: "moj",
          permitted_case_types: {
            foi: "Freedom of information request",
          },
        },
        case_types: {
          foi: {
            name: "Freedom of Information Request",
            permitted_workflows: %w[standard review_for_compliance review_for_timeliness],
            permitted_user_roles: %w[manager approver responder],
            permitted_states: %w[unassigned drafting awaiting_responder responded],
            workflows: {
              standard: {
                initial_state: "unassigned",
                user_roles: {
                  manager: {
                    states: {
                      unassigned: {
                        add_message_to_case: {
                          if: "Case::FOI::StandardPolicy#can_add_message_to_case?",
                          transition_to: nil,
                          before_transition: nil,
                          after_transition: nil,
                          switch_workflow: nil,
                        },
                        assign_responder: {
                          transition_to: "awaiting_responder",
                        },
                        destroy_case: nil,
                        edit_case: nil,
                        flag_for_clearance: nil,
                        unflag_for_clearance: nil,
                      },
                      drafting: {
                        edit_case: {
                          if: "Case::FOI::StandardPolicy#show?",
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      }
    end

    let(:filename) { File.join(File.dirname(__FILE__), "data", "config.yml") }

    context "when validation of full valid file" do
      it "is valid" do
        validator = ConfigValidator.new(config, filename)
        expect {
          validator.run
        }.not_to raise_error
      end
    end

    context "when validation of root" do
      context "and missing mandatory keys" do
        it "errors" do
          config.delete_field(:preamble)
          validator = ConfigValidator.new(config, filename)
          expect {
            validator.run
          }.to raise_error ConfigurationError, "File #{filename} section root: Missing mandatory key: 'preamble'\nFile #{filename} section root: Expected preamble to be a Hash, is a NilClass"
        end
      end

      context "and additional unknown keys" do
        it "errors" do
          config.gobbledegook = "ddddd"
          validator = ConfigValidator.new(config, filename)
          expect {
            validator.run
          }.to raise_error ConfigurationError, "File #{filename} section root: Invalid key: 'gobbledegook'"
        end
      end
    end

    context "when validation of preamble" do
      context "and preamble is  not a hash" do
        it "errors" do
          config.preamble = %w[dog cat mouse]
          validator = ConfigValidator.new(config, filename)
          expect {
            validator.run
          }.to raise_error ConfigurationError, "File #{filename} section root: Expected preamble to be a Hash, is a Array"
          # expect(validator).not_to be_valid
          # expect(validator.errors).to eq ["File #{filename} section root: Expected preamble to be a Hash, is a Array"]
        end
      end

      context "and missing keys" do
        it "errors" do
          config.preamble.delete_field(:organisation_abbreviation)
          validator = ConfigValidator.new(config, filename)
          expect {
            validator.run
          }.to raise_error ConfigurationError, "File #{filename} section preamble: Missing mandatory key: 'organisation_abbreviation'"
        end
      end

      context "and extra keys" do
        it "errors" do
          config.preamble.codex = "abd"
          validator = ConfigValidator.new(config, filename)
          expect {
            validator.run
          }.to raise_error ConfigurationError, "File #{filename} section preamble: Invalid key: 'codex'"
        end
      end
    end

    context "when validation of preamble/permitted_case_types" do
      it "errors if none specified" do
        config.preamble.permitted_case_types = RecursiveOpenStruct.new({})
        validator = ConfigValidator.new(config, filename)
        expect {
          validator.run
        }.to raise_error ConfigurationError, /File #{filename} section preamble\/permitted_case_types: expected at least 1 entries, found 0/
      end
    end

    context "when validation of case_types" do
      it "errors if no case type entry for  thise specified in preamble/permitted_case_types" do
        config.preamble.permitted_case_types.pq = "Parliamentary Questions"
        validator = ConfigValidator.new(config, filename)
        expect {
          validator.run
        }.to raise_error ConfigurationError, "File #{filename} section case_types: Missing mandatory key: 'pq'"
      end

      it "errors if case type entry specified which is not mentioned in peramble/permitted_case_types" do
        config.case_types.pq = { a: "A" }
        validator = ConfigValidator.new(config, filename)
        expect {
          validator.run
        }.to raise_error ConfigurationError, /File #{filename} section case_types: Invalid key: 'pq'/
      end
    end

    describe "validation of a single case type" do
      context "when name attribute" do
        it "errors if missing" do
          config.case_types.foi.delete_field(:name)
          validator = ConfigValidator.new(config, filename)
          expect {
            validator.run
          }.to raise_error ConfigurationError, %(File #{filename} section case_types/foi: Missing mandatory key: 'name')
        end
      end

      context "when permitted workflows is not an array" do
        it "errors" do
          config.case_types.foi.permitted_workflows = RecursiveOpenStruct.new({ a: "kkkkk" })
          validator = ConfigValidator.new(config, filename)
          expect {
            validator.run
          }.to raise_error ConfigurationError, /File #{filename} section case_types\/foi\/permitted_workflows: Expected an array, got RecursiveOpenStruct/
        end
      end

      context "when permitted workflows is an Integer" do
        it "errors" do
          config.case_types.foi.permitted_workflows = 55
          validator = ConfigValidator.new(config, filename)
          expect {
            validator.run
          }.to raise_error ConfigurationError, /File #{filename} section case_types\/foi\/permitted_workflows: Expected an array, got Integer/
        end
      end

      context "when permitted states is not an array" do
        it "errors" do
          config.case_types.foi.permitted_states = "abc"
          validator = ConfigValidator.new(config, filename)
          expect {
            validator.run
          }.to raise_error ConfigurationError, /File #{filename} section case_types\/foi\/permitted_states: Expected an array, got String/
        end
      end

      context "when validation of workflows" do
        context "and workflows is not a hash" do
          it "errors" do
            config.case_types.foi.workflows = 33
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, "File #{filename} section case_types/foi: Expected workflows to be a Hash, is a Integer"
          end
        end

        context "and workflow name is not valid" do
          it "errors" do
            config.case_types.foi.workflows.fantasy_workflow = {}
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, "File #{filename} section case_types/foi/workflows: fantasy_workflow is not a permitted workflow"
          end
        end

        context "and workflow is missing initial state" do
          it "errors" do
            config.case_types.foi.workflows.standard.delete_field(:initial_state)
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, "File #{filename} section case_types/foi/workflows/standard: Mandatory key :initial_state not specified"
          end
        end

        context "and initial_state is not a permitted state" do
          it "errors" do
            config.case_types.foi.workflows.standard.initial_state = :unknown
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, "File #{filename} section case_types/foi/workflows/standard: Initial state unknown is not a permitted state"
          end
        end

        context "and workflow is missing user roles" do
          it "errors" do
            config.case_types.foi.workflows.standard.delete_field(:user_roles)
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, "File #{filename} section case_types/foi/workflows/standard: Missing mandatory key: user_roles"
          end
        end

        context "and user roles is not a hash" do
          it "errors" do
            config.case_types.foi.workflows.standard.user_roles = 55
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, "File #{filename} section case_types/foi/workflows/standard: Expected user_roles to be a Hash, got Integer"
          end
        end

        context "and not all user roles are in permitted roles" do
          it "errors" do
            config.case_types.foi.workflows.standard.user_roles.drafter = {}
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, "File #{filename} section case_types/foi/workflows/standard/user_roles: User role drafter is not a permitted user role"
          end
        end
      end

      context "when validate user role" do
        context "and user role is not a hash" do
          it "errors" do
            config.case_types.foi.workflows.standard.user_roles.manager = "xxx"
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, "File #{filename} section case_types/foi/workflows/standard/user_roles: Expected manager to be a hash, is a String"
          end
        end

        context "and user role doesnt have states key" do
          it "errors" do
            config.case_types.foi.workflows.standard.user_roles.manager.case_states = {}
            config.case_types.foi.workflows.standard.user_roles.manager.delete_field(:states)
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, /File #{filename} section case_types\/foi\/workflows\/standard\/user_roles\/manager: Missing mandatory key: 'states'/
          end
        end

        context "and user role has an unrecognised key" do
          it "errors" do
            config.case_types.foi.workflows.standard.user_roles.manager.case_states = {}
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, "File #{filename} section case_types/foi/workflows/standard/user_roles/manager: Invalid key: 'case_states'"
          end
        end
      end

      context "when validate user_role/state" do
        context "and unknown state specified" do
          it "errors" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.unrecognised = {}
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, "File #{filename} section case_types/foi/workflows/standard/user_roles/manager/states/: State unrecognised not a permitted state"
          end
        end

        context "and state is not a hash" do
          it "errors" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.drafting = "kjkjkjkj"
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, "File #{filename} section case_types/foi/workflows/standard/user_roles/manager/states: Expected drafting to be a Hash, is a String"
          end
        end
      end

      describe "validate_event" do
        context "when invalid key" do
          it "errors" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.drafting.edit_case.summarize = "Proc#summary"
            validator = ConfigValidator.new(config, filename)
            expect {
              validator.run
            }.to raise_error ConfigurationError, "File #{filename} section case_types/foi/workflows/standard/user_roles/manager/states/drafting/edit_case: Unrecognised key: summarize"
          end
        end

        context "when transition_to_using" do
          it "does not error if no transition_to_using is supplied" do
            hash = config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.to_h
            expect(hash.key?(:transition_to_using)).to be false
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.not_to raise_error
          end

          it "does not error if 'transition_to_using' value is nil" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.transition_to_using = nil
            expect(config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.to_h[:transition_to_using]).to be_nil
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.not_to raise_error
          end

          it "raises if the conditional class doesnt exist" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.transition_to_using = "NonExistentClass#dummy_method"
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.to raise_error ConfigurationError do |error|
              expect(error.message).to match(/case_types\/foi\/workflows\/standard\/user_roles\/manager\/states\/unassigned\/assign_responder/)
              expect(error.message).to match(/No such class: NonExistentClass/)
            end
          end

          it "does not error if specified method exists on specified object" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.transition_to_using = "ConfigurableStateMachine::DummyPredicate#can_assign_responder?"
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.not_to raise_error
          end

          it "raises if the specified method does not exist on the specified object" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.transition_to_using = "ConfigurableStateMachine::DummyPredicate#can_assign_manager?"
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.to raise_error ConfigurationError do |error|
              expect(error.message).to match(/case_types\/foi\/workflows\/standard\/user_roles\/manager\/states\/unassigned\/assign_responder/)
              expect(error.message).to match(/No such instance method 'can_assign_manager\?' on class ConfigurableStateMachine::DummyPredicate/)
            end
          end
        end

        context "when predicate" do
          it "does not error if no if is supplied" do
            hash = config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.to_h
            expect(hash.key?(:if)).to be false
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.not_to raise_error
          end

          it "does not error if 'if' value is nil" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.if = nil
            expect(config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.to_h[:if]).to be_nil
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.not_to raise_error
          end

          it "raises if the predicate class doesnt exist" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.if = "NonExistentClass#dummy_method"
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.to raise_error ConfigurationError do |error|
              expect(error.message).to match(/case_types\/foi\/workflows\/standard\/user_roles\/manager\/states\/unassigned\/assign_responder/)
              expect(error.message).to match(/No such class: NonExistentClass/)
            end
          end

          it "does not error if specified method exists on specified object" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.if = "ConfigurableStateMachine::DummyPredicate#can_assign_responder?"
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.not_to raise_error
          end

          it "raises if the specified method does not exist on the specified object" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.if = "ConfigurableStateMachine::DummyPredicate#can_assign_manager?"
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.to raise_error ConfigurationError do |error|
              expect(error.message).to match(/case_types\/foi\/workflows\/standard\/user_roles\/manager\/states\/unassigned\/assign_responder/)
              expect(error.message).to match(/No such instance method 'can_assign_manager\?' on class ConfigurableStateMachine::DummyPredicate/)
            end
          end
        end

        context "when after_transition" do
          it "does not error if no after_transition is supplied" do
            hash = config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.to_h
            expect(hash.key?(:after_transition)).to be false
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.not_to raise_error
          end

          it "does not error if 'after_transition' value is nil" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.after_transition = nil
            expect(config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.to_h[:after_transition]).to be_nil
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.not_to raise_error
          end

          it "does not error if specified method exists on specified object" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.after_transition = "ConfigurableStateMachine::DummyPredicate#can_assign_responder?"
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.not_to raise_error
          end

          it "raises if the specified method does not exist on the specified object" do
            config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.after_transition = "ConfigurableStateMachine::DummyPredicate#can_assign_manager?"
            validator = ConfigValidator.new(config, filename)
            expect { validator.run }.to raise_error ConfigurationError do |error|
              expect(error.message).to match(/case_types\/foi\/workflows\/standard\/user_roles\/manager\/states\/unassigned\/assign_responder/)
              expect(error.message).to match(/No such instance method 'can_assign_manager\?' on class ConfigurableStateMachine::DummyPredicate/)
            end
          end
        end

        context "when switch workflow" do
          context "and no switch workflow" do
            it "is valid" do
              hash = config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.to_h
              expect(hash.key?(:switch_workflow)).to be false
              validator = ConfigValidator.new(config, filename)
              expect { validator.run }.not_to raise_error
            end
          end

          context "and switch workflow to nil" do
            it "is valid" do
              config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.switch_workflow = nil
              expect(config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.to_h[:switch_workflow]).to be_nil
              validator = ConfigValidator.new(config, filename)
              expect { validator.run }.not_to raise_error
            end
          end

          context "and switching workflow to current workflow" do
            it "is invalid" do
              config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.switch_workflow = "standard"
              validator = ConfigValidator.new(config, filename)
              expect { validator.run }.to raise_error ConfigurationError do |error|
                expect(error.message).to match(/case_types\/foi\/workflows\/standard\/user_roles\/manager\/states\/unassigned\/assign_responder/)
                expect(error.message).to match(/Cannot switch workflow to the current workflow/)
              end
            end
          end

          context "and switching workflow to workflow not declared in permitted workflows" do
            it "is invalid" do
              config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.switch_workflow = "non-existent-workflow"
              validator = ConfigValidator.new(config, filename)
              expect { validator.run }.to raise_error ConfigurationError do |error|
                expect(error.message).to match(/case_types\/foi\/workflows\/standard\/user_roles\/manager\/states\/unassigned\/assign_responder/)
                expect(error.message).to match(/Invalid workflow: non-existent-workflow/)
              end
            end
          end

          context "and switching workflow to other valid workflow" do
            it "is valid" do
              config.case_types.foi.workflows.standard.user_roles.manager.states.unassigned.assign_responder.switch_workflow = "review_for_compliance"
              validator = ConfigValidator.new(config, filename)
              expect { validator.run }.not_to raise_error
            end
          end
        end
      end
    end
  end
end
