require "rails_helper"

describe CasesController, type: :controller do
  let(:case_being_drafted) { create :case_being_drafted }
  let(:manager)            { create :manager }

  before do
    sign_in manager
  end

  describe 'PATCH execute_extend_for_pit' do
    it 'authorizes' do
      expect {
        patch :execute_extend_for_pit,
              params: { id: case_being_drafted.id,
                        case: {
                          external_deadline_yyyy: '2017',
                          external_deadline_mm:   '02',
                          external_deadline_dd:   '10',
                          reason_for_extending:   'need more time',
                        }
                      }
      } .to require_permission(:execute_request_amends?)
              .with_args(manager, case_being_drafted)
    end
  end
end
