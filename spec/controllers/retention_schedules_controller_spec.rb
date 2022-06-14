require 'rails_helper'

RSpec.describe RetentionSchedulesController, type: :controller do
  let(:team_admin) { find_or_create :team_admin }

  let(:case_with_rrd) {
    create(
      :offender_sar_case, :closed, :with_retention_schedule,
      planned_destruction_date: Date.tomorrow
    )
  }

  let(:retention_schedule) { case_with_rrd.retention_schedule }

  # TODO: implement proper access control and add tests here when ready.

  describe '#edit' do
    context 'when user has access' do
      before do
        sign_in team_admin
      end

      it 'builds the form object and renders the view' do
        get :edit, params: { id: retention_schedule.id }

        expect(assigns(:case)).to eq(case_with_rrd)
        expect(assigns(:form_object).record).to eq(retention_schedule)

        expect(response).to render_template(:edit)
      end

      context 'when the retention schedule does not exist' do
        it 'raises an exception' do
          expect {
            get :edit, params: { id: 12345 }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe '#update' do
    context 'when user has access' do
      before do
        sign_in team_admin
      end

      context 'when the update was successful' do
        it 'redirects back to the case details page, showing a flash notice' do
          patch :update, params: {
            id: retention_schedule.id,
            retention_schedule_form: {
              planned_destruction_date_yyyy: 2050,
              planned_destruction_date_mm: 12,
              planned_destruction_date_dd: 31
            }
          }

          expect(retention_schedule.reload.planned_destruction_date).to eq(Date.new(2050, 12, 31))

          expect(flash[:notice]).to eq('Retention details updated')
          expect(response).to redirect_to(case_path(case_with_rrd))
        end
      end

      context 'when the update failed' do
        it 'renders the `edit` action showing errors' do
          patch :update, params: { id: retention_schedule.id }

          expect(assigns(:case)).to eq(case_with_rrd)
          expect(assigns(:form_object).errors.added?(:planned_destruction_date, :blank)).to eq(true)

          expect(response).to render_template(:edit)
        end
      end

      context 'when the retention schedule does not exist' do
        it 'raises an exception' do
          expect {
            patch :update, params: { id: 12345 }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
