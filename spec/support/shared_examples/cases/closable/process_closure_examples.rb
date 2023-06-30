require "rails_helper"

# Ensure a valid `kase` and `params` is declared in calling test
RSpec.shared_examples "process closure spec" do |klass|
  describe klass do
    describe "#process_closure" do
      let(:manager) { find_or_create :disclosure_bmt_user }

      context "when an authenticated manager" do
        before { sign_in manager }

        it "authorizes using can_close_case?" do
          expect {
            patch :process_closure, params:
          }.to require_permission(:can_close_case?)
            .with_args(manager, kase)
        end

        it "closes a case that has been responded to" do
          patch(:process_closure, params:)
          kase.reload

          expect(kase.current_state).to eq "closed"
          expect(kase.outcome_id).to eq outcome.id
          expect(kase.date_responded).to eq 3.days.ago.to_date
        end
      end
    end
  end
end
