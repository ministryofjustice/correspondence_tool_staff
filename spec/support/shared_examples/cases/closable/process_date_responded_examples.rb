require "rails_helper"

# Ensure a valid `kase` and `params` is declared in calling test
RSpec.shared_examples "process date responded spec" do |klass|
  describe klass do
    let(:manager) { find_or_create :disclosure_bmt_user }
    let(:responded_case) { kase }
    let(:date_responded) { responded_case.created_at + 5.working.days }
    let(:params) do
      {
        id: responded_case.id,
        responded_case.type_abbreviation.downcase.to_sym => {
          date_responded_dd: date_responded.day.to_s,
          date_responded_mm: date_responded.month.to_s,
          date_responded_yyyy: date_responded.year.to_s,
        },
      }
    end

    before do
      sign_in manager
    end

    it "authorises can_close_case?" do
      expect {
        patch :process_date_responded, params:
      }.to require_permission(:can_close_case?)
             .with_args(manager, responded_case)
    end

    context "when valid date responded entered" do
      it "sets the date responded" do
        patch(:process_date_responded, params:)

        responded_case.reload
        expect(responded_case.date_responded).to eq date_responded.to_date
      end

      it "defaults case lateness to responding team" do
        patch(:process_date_responded, params:)

        responded_case.reload
        expect(responded_case.late_team).to eq responded_case.responding_team
      end

      it "redirects to the closure outcomes page" do
        patch(:process_date_responded, params:)

        expect(response).to redirect_to(polymorphic_path(responded_case, action: :closure_outcomes))
      end
    end
  end
end
