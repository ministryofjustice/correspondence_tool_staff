require 'rails_helper'

#rubocop:disable Metrics/ModuleLength
module ConfigurableStateMachine

  describe 'ConfigValidator' do
    let(:config) { RecursiveOpenStruct.new(config_as_hash) }
    let(:config_as_hash) do
      {
        preamble: {
          organisation: 'Ministry of Justice',
          organisation_abbreviation: 'moj',
          permitted_correspondence_types: {
            foi: 'Freedom of information request',
          }
        },
        correspondence_types: {
          foi: {
            name: 'Freedom of Information Request',
            permitted_workflows: %w{ standard review_for_compliance review_for_timeliness },
            permitted_user_roles: %w{ manager approver responder },
            permitted_states: %w{ unassigned drafting awaiting_responder responded },
            workflows: {
              standard: {
                initial_state: 'unassigned',
                user_roles: {
                  manager: {
                    states: {
                      unassigned: {
                        add_message_to_case: {
                          if: 'Cases::BasePolicy#can_add_message_to_case?',
                          transition_to: nil,
                          before_transition: nil,
                          after_transition: nil,
                          switch_workflow: nil
                        },
                        assign_responder: {
                          transition_to: 'awaiting_responder'
                        },
                        destroy_case: nil,
                        edit_case: nil,
                        flag_for_clearance: nil,
                        unflag_for_clearance: nil
                      },
                      drafting: {
                        edit_case: {
                          if: 'Cases#BaseCase.editable?'
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    end

    context 'validation of full valid file' do
      it 'is valid' do
        validator = ConfigValidator.new(config, 'xxx.yml')
        expect{
          validator.run
        }.not_to raise_error
      end
    end

    context 'validation of root' do
      context 'missing mandatory keys' do
        it 'errors' do
          config.delete_field(:preamble)
          validator = ConfigValidator.new(config, 'xxx.yml')
          expect{
            validator.run
          }.to raise_error ConfigurationError, "File xxx.yml section root: Missing mandatory key: 'preamble'\nFile xxx.yml section root: Expected preamble to be a Hash, is a NilClass"
        end
      end
      context 'additional unknown keys' do
        it 'errors' do
          config.gobbledegook = 'ddddd'
          validator = ConfigValidator.new(config, 'xxx.yml')
          expect{
            validator.run
          }.to raise_error ConfigurationError, "File xxx.yml section root: Invalid key: 'gobbledegook'"
        end
      end
    end

    context 'validation of preamble' do

      context 'preamble is  not a hash' do
        it 'errors' do
          config.preamble = %w{ dog cat mouse }
          validator = ConfigValidator.new(config, 'xxx.yml')
          expect{
            validator.run
          }.to raise_error ConfigurationError, "File xxx.yml section root: Expected preamble to be a Hash, is a Array"
          # expect(validator).not_to be_valid
          # expect(validator.errors).to eq ["File xxx.yml section root: Expected preamble to be a Hash, is a Array"]
        end
      end
      context 'missing keys' do
        it 'errors' do
          config.preamble.delete_field(:organisation_abbreviation)
          validator = ConfigValidator.new(config, 'xxx.yml')
          expect{
            validator.run
          }.to raise_error ConfigurationError, "File xxx.yml section preamble: Missing mandatory key: 'organisation_abbreviation'"
        end
      end

      context 'extra keys' do
        it 'errors' do
          config.preamble.codex = 'abd'
          validator = ConfigValidator.new(config, 'xxx.yml')
          expect{
            validator.run
          }.to raise_error ConfigurationError, "File xxx.yml section preamble: Invalid key: 'codex'"
        end
      end
    end

    context 'validation of preamble/permitted_correspondence_types' do
      it 'should error if none specified' do
        config.preamble.permitted_correspondence_types = RecursiveOpenStruct.new( {} )
        validator = ConfigValidator.new(config, 'xxx.yml')
        expect{
          validator.run
        }.to raise_error ConfigurationError, /File xxx.yml section preamble\/permitted_correspondence_types: expected at least 1 entries, found 0/
      end
    end

    context 'validation of correspondence_types' do
      it 'errors if no correspondence type entry for  thise specified in preamble/permitted_correspondence_types' do
        config.preamble.permitted_correspondence_types.pq = 'Parliamentary Questions'
        validator = ConfigValidator.new(config, 'xxx.yml')
        expect{
          validator.run
        }.to raise_error ConfigurationError,"File xxx.yml section correspondence_types: Missing mandatory key: 'pq'"
      end

      it 'errors if correspondence type entry specified which is not mentioned in peramble/permitted_correspondence_types' do
        config.correspondence_types.pq = {a: 'A'}
        validator = ConfigValidator.new(config, 'xxx.yml')
        expect{
          validator.run
        }.to raise_error ConfigurationError, /File xxx.yml section correspondence_types: Invalid key: 'pq'/
      end
    end

    context 'validation of a single correspondence type' do
      context 'name attribute' do
        it 'errors if missing' do
          config.correspondence_types.foi.delete_field(:name)
          validator = ConfigValidator.new(config, 'xxx.yml')
          expect{
            validator.run
          }.to raise_error ConfigurationError, %q{File xxx.yml section correspondence_types/foi: Missing mandatory key: 'name'}
        end
      end

      context 'permitted workflows is not an array' do
        it 'errors' do
          config.correspondence_types.foi.permitted_workflows = RecursiveOpenStruct.new( { a: 'kkkkk'} )
          validator = ConfigValidator.new(config, 'xxx.yml')
          expect{
            validator.run
          }.to raise_error ConfigurationError, /File xxx.yml section correspondence_types\/foi\/permitted_workflows: Expected an array, got RecursiveOpenStruct/
        end
      end

      context 'permitted user_roles is not an array' do
        it 'errors' do
          config.correspondence_types.foi.permitted_workflows = 55
          validator = ConfigValidator.new(config, 'xxx.yml')
          expect{
            validator.run
          }.to raise_error ConfigurationError, /File xxx.yml section correspondence_types\/foi\/permitted_workflows: Expected an array, got Fixnum/
        end
      end

      context 'permitted user_roles is not an array' do
        it 'errors' do
          config.correspondence_types.foi.permitted_states = 'abc'
          validator = ConfigValidator.new(config, 'xxx.yml')
          expect{
            validator.run
          }.to raise_error ConfigurationError, /File xxx.yml section correspondence_types\/foi\/permitted_states: Expected an array, got String/
        end
      end

      context 'validation of workflows' do
        context 'workflows is not a hash' do
          it 'errors' do
            config.correspondence_types.foi.workflows = 33
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, 'File xxx.yml section correspondence_types/foi: Expected workflows to be a Hash, is a Fixnum'
          end
        end

        context 'workflow name is not valid' do
          it 'errors' do
            config.correspondence_types.foi.workflows.fantasy_workflow = {}
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, 'File xxx.yml section correspondence_types/foi/workflows: fantasy_workflow is not a permitted workflow'
          end
        end

        context 'workflow is missing initial state' do
          it 'errors' do
            config.correspondence_types.foi.workflows.standard.delete_field(:initial_state)
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, 'File xxx.yml section correspondence_types/foi/workflows/standard: Mandatory key :initial_state not specified'
          end
        end

        context 'initial_state is not a permitted state' do
          it 'errors' do
            config.correspondence_types.foi.workflows.standard.initial_state = :unknown
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, 'File xxx.yml section correspondence_types/foi/workflows/standard: Initial state unknown is not a permitted state'
          end
        end

        context 'workflow is missing user roles' do
          it 'errors' do
            config.correspondence_types.foi.workflows.standard.delete_field(:user_roles)
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, 'File xxx.yml section correspondence_types/foi/workflows/standard: Missing mandatory key: user_roles'
          end
        end

        context 'user roles is not a hash' do
          it 'errors' do
            config.correspondence_types.foi.workflows.standard.user_roles = 55
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, 'File xxx.yml section correspondence_types/foi/workflows/standard: Expected user_roles to be a Hash, got Fixnum'
          end
        end

        context 'not all user roles are in permitted roles' do
          it 'errors' do
            config.correspondence_types.foi.workflows.standard.user_roles.drafter = {}
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, 'File xxx.yml section correspondence_types/foi/workflows/standard/user_roles: User role drafter is not a permitted user role'
          end
        end
      end

      context 'validate user role' do
        context 'user role is not a hash' do
          it 'errors' do
            config.correspondence_types.foi.workflows.standard.user_roles.manager = 'xxx'
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, 'File xxx.yml section correspondence_types/foi/workflows/standard/user_roles: Expected manager to be a hash, is a String'
          end
        end
        context 'user role doesnt have states key' do
          it 'errors' do
            config.correspondence_types.foi.workflows.standard.user_roles.manager.case_states = {}
            config.correspondence_types.foi.workflows.standard.user_roles.manager.delete_field(:states)
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, /File xxx.yml section correspondence_types\/foi\/workflows\/standard\/user_roles\/manager: Missing mandatory key: 'states'/
          end
        end
        context 'user role has an unrecognised key' do
          it 'errors' do
            config.correspondence_types.foi.workflows.standard.user_roles.manager.case_states = {}
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, "File xxx.yml section correspondence_types/foi/workflows/standard/user_roles/manager: Invalid key: 'case_states'"
          end
        end
      end

      context 'validate user_role/state' do
        context 'unknown state specified' do
          it 'errors' do
            config.correspondence_types.foi.workflows.standard.user_roles.manager.states.unrecognised = {}
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, "File xxx.yml section correspondence_types/foi/workflows/standard/user_roles/manager/states/: State unrecognised not a permitted state"
          end
        end

        context 'state is not a hash' do
          it 'errors' do
            config.correspondence_types.foi.workflows.standard.user_roles.manager.states.drafting = 'kjkjkjkj'
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, "File xxx.yml section correspondence_types/foi/workflows/standard/user_roles/manager/states: Expected drafting to be a Hash, is a String"
          end
        end
      end

      context 'validate_event' do
        context 'invalid key' do
          it 'errors' do
            config.correspondence_types.foi.workflows.standard.user_roles.manager.states.drafting.edit_case.summarize = 'Proc#summary'
            validator = ConfigValidator.new(config, 'xxx.yml')
            expect{
              validator.run
            }.to raise_error ConfigurationError, "File xxx.yml section correspondence_types/foi/workflows/standard/user_roles/manager/states/drafting/edit_case: Unrecognised key: summarize"
          end
        end
      end
    end
  end
end
#rubocop:enable Metrics/ModuleLength
