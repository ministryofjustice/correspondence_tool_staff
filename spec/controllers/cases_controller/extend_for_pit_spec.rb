require "rails_helper"

describe CasesController, type: :controller do
  let(:case_being_drafted) { create :case_being_drafted }
  let(:manager)            { create :disclosure_bmt_user }

  before do
    sign_in manager
  end

  describe 'GET extend_for_pit' do
    it 'authorizes' do
      expect { get :extend_for_pit, params: { id: case_being_drafted.id } }
        .to require_permission(:execute_extend_for_pit?)
              .with_args(manager, case_being_drafted)
    end

    it 'assigns case object' do
      get :extend_for_pit, params: { id: case_being_drafted.id }
      expect(assigns(:case)).to be_a CaseExtendForPITDecorator
      expect(assigns(:case).object).to be_a CaseDecorator
      expect(assigns(:case).object.object).to eq case_being_drafted
    end
  end
end
