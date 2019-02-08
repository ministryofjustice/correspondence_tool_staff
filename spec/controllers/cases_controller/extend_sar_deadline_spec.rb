require "rails_helper"

describe CasesController, type: :controller do
  let(:sar_case)          { create :sar_case }
  let(:extended_sar_case) { create :extended_deadline_sar }
  let(:manager)           { find_or_create :disclosure_bmt_user }

  before do
    sign_in manager
  end

  describe 'GET extend_sar_deadline' do
    it 'authorizes' do
      expect {
        get :extend_sar_deadline,
        params: {
          id: sar_case.id
        }
      }
      .to require_permission(:extend_sar_deadline?)
            .with_args(manager, sar_case)

      expect(assigns(:case)).to be_a CaseExtendSARDeadlineDecorator
    end
  end

  describe 'PATCH execute_extend_sar_deadline_case' do
    it 'authorizes' do
      expect {
        patch :execute_extend_sar_deadline,
        params: {
          id: sar_case.id,
          case: {
            extension_period: '30',
            reason_for_extension: 'A decent reason'
          }
        }
      }
      .to require_permission(:extend_sar_deadline?)
            .with_args(manager, sar_case)

      expect(assigns(:case)).to be_a CaseExtendSARDeadlineDecorator
    end
  end

  describe 'PATCH remove_sar_deadline_extension_case' do
    it 'authorizes' do
      expect {
        patch :remove_sar_deadline_extension,
        params: {
          id: extended_sar_case.id
        }
      }
      .to require_permission(:remove_sar_deadline_extension?)
            .with_args(manager, extended_sar_case)
    end
  end
end
