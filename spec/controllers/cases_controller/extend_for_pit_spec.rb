require "rails_helper"

describe CasesController, type: :controller do
  let(:case_being_drafted)   { create :case_being_drafted,
                                :flagged_accepted }
  let(:manager)           { create :disclosure_bmt_user}

  before do
    sign_in manager
  end

  describe 'GET extend_for_pit' do
    it 'authorizes' do
      expect { get :extend_for_pit, params: { id: case_being_drafted.id } }
        .to require_permission(:extend_for_pit?)
              .with_args(manager, case_being_drafted)
    end

    it 'assigns case object' do
      get :extend_for_pit, params: { id: case_being_drafted.id }
      expect(assigns(:case)).to be_a CaseExtendForPITDecorator
      expect(assigns(:case).object).to eq case_being_drafted
    end
  end
end
