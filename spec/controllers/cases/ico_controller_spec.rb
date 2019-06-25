require "rails_helper"

RSpec.describe Cases::IcoController, type: :controller do
  describe 'FOI' do
    describe '#close' do
      let(:kase) { create :responded_ico_foi_case }

      include_examples 'close spec', described_class
    end

    describe '#closure_outcomes' do
      let(:kase) { create :responded_ico_foi_case }

      include_examples 'closure outcomes spec', described_class
    end

    describe '#edit_closure' do
      let(:kase)    { create :closed_ico_foi_case }
      let(:manager) { find_or_create :disclosure_bmt_user }

      include_examples 'edit closure spec', described_class
    end

    describe '#confirm_respond' do
      let(:approver) { find_or_create :disclosure_specialist }
      let(:approved_ico) { create :approved_ico_foi_case }
      let(:date_responded) { approved_ico.received_date + 2.days }
      let(:params) do
        {
          correspondence_type: 'ico',
          ico:  {
            date_responded_dd: date_responded.day,
            date_responded_mm: date_responded.month,
            date_responded_yyyy: date_responded.year,
          },
          commit: 'Submit',
          id:  approved_ico.id.to_s
        }
      end

      context 'as the assigned approver' do
        before { sign_in approver }

        it 'transitions current_state to "responded"' do
          stub_find_case(approved_ico.id) do |kase|
            expect(kase).to receive(:respond).with(approver)
          end
          patch :confirm_respond, params: params
        end

        it 'redirects to the case list view' do
          expect(patch :confirm_respond, params: params).
            to redirect_to(case_path(approved_ico))
        end
      end
    end
  end

  describe 'SAR' do
    describe '#closure_outcomes' do
      let(:kase) { create :responded_ico_sar_case }

      include_examples 'closure outcomes spec', described_class
    end

    describe '#edit_closure' do
      let(:kase)    { create :closed_ico_sar_case }
      let(:manager) { find_or_create :disclosure_bmt_user }

      include_examples 'edit closure spec', described_class
    end
  end
end
