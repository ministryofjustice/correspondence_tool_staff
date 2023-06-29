require "rails_helper"

RSpec.describe RetentionSchedulesController, type: :controller do
  let(:admin_team) { find_or_create :team_for_admin_users }

  let(:branston_team_admin_user) { find_or_create :branston_user }
  let(:branston_user) { create :branston_user, email: "non.team.admin@test.com" }

  let(:case_with_rrd) do
    create(
      :offender_sar_case, :closed, :with_retention_schedule,
      planned_destruction_date: Date.new(2024, 12, 18)
    )
  end

  let(:retention_schedule) { case_with_rrd.retention_schedule }

  before do
    tur = TeamsUsersRole.new(
      team_id: admin_team.id,
      user_id: branston_team_admin_user.id,
      role: "team_admin",
    )

    branston_team_admin_user.team_roles << tur
  end

  describe "#edit" do
    context "when user has access" do
      before do
        sign_in branston_team_admin_user
      end

      it "builds the form object and renders the view" do
        get :edit, params: { id: retention_schedule.id }

        expect(assigns(:case)).to eq(case_with_rrd)
        expect(assigns(:form_object).record).to eq(retention_schedule)

        expect(response).to render_template(:edit)
      end

      context "when the retention schedule does not exist" do
        it "raises an exception" do
          expect {
            get :edit, params: { id: 12_345 }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "when user has no access" do
      before do
        sign_in branston_user
      end

      it "is not authorised" do
        get :edit, params: { id: retention_schedule.id }

        expect(flash[:alert]).to eq "You are not authorised to edit the retention details of this case."
        expect(response).to redirect_to root_path
      end
    end
  end

  describe "#update" do
    context "when user has access" do
      before do
        sign_in branston_team_admin_user
      end

      context "when the update was successful" do
        it "redirects back to the case details page, showing a flash notice" do
          patch :update, params: {
            id: retention_schedule.id,
            retention_schedule_form: {
              planned_destruction_date_yyyy: 2050,
              planned_destruction_date_mm: 12,
              planned_destruction_date_dd: 31,
              state: RetentionSchedule::STATE_REVIEW,
            },
          }

          expect(retention_schedule.reload.review?).to eq(true)
          expect(retention_schedule.reload.planned_destruction_date).to eq(Date.new(2050, 12, 31))

          last_history_message = case_with_rrd.transitions.case_history.last.message
          expect(last_history_message).to eq("Retention status changed from Not set to Review\nDestruction date changed from 18-12-2024 to 31-12-2050")

          expect(flash[:notice]).to eq("Retention details successfully updated")
          expect(response).to redirect_to(case_path(case_with_rrd))
        end
      end

      context "when the update failed" do
        it "renders the `edit` action showing errors" do
          patch :update, params: { id: retention_schedule.id }

          expect(assigns(:case)).to eq(case_with_rrd)
          expect(assigns(:form_object).errors.added?(:planned_destruction_date, :blank)).to eq(true)

          expect(response).to render_template(:edit)
        end
      end

      context "when the retention schedule does not exist" do
        it "raises an exception" do
          expect {
            patch :update, params: { id: 12_345 }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "when user has no access" do
      before do
        sign_in branston_user
      end

      it "is not authorised" do
        patch :update, params: { id: retention_schedule.id }

        expect(flash[:alert]).to eq "You are not authorised to edit the retention details of this case."
        expect(response).to redirect_to root_path
      end
    end
  end
end
