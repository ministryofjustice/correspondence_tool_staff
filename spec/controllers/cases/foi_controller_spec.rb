require "rails_helper"

RSpec.describe Cases::FoiController, type: :controller do
  describe 'closeable' do
    describe '#closure_outcomes' do
      let(:kase) { create :responded_case }

      include_examples 'closure outcomes spec', described_class
    end

    describe '#respond' do
      let(:responder) { find_or_create(:foi_responder) }
      let(:responding_team) { responder.responding_teams.first }
      let(:kase) {
        create(
          :case_with_response,
          responder: responder,
          responding_team: responding_team
        )
      }

      include_examples 'respond spec', described_class
    end

    describe '#confirm_respond' do
      let(:kase) { create :case_with_response }

      include_examples 'confirm respond spec', described_class
    end

    describe '#process_closure' do
      context 'with valid params' do
        let(:responder) { find_or_create :foi_responder }
        let(:responding_team) { responder.responding_teams.first }
        let(:outcome) { find_or_create :outcome, :requires_refusal_reason }
        let(:info_held) { find_or_create :info_status, :held }
        let(:date_responded) { 3.days.ago }
        let(:kase) {
          create(
            :responded_case,
            responder: responder,
            responding_team: responding_team,
            received_date: 5.days.ago
          )
        }
        let(:params) {
          {
            id: kase.id,
            foi: {
              date_responded_dd: date_responded.day,
              date_responded_mm: date_responded.month,
              date_responded_yyyy: date_responded.year,
              info_held_status_abbreviation: info_held.abbreviation,
              outcome_abbreviation: outcome.abbreviation,
            }
          }
        }

        include_examples 'process closure spec', described_class
      end

      context 'FOI internal review' do
        let(:appeal_outcome) { find_or_create :appeal_outcome, :upheld }
        let(:internal_review) { create :responded_compliance_review }
        let(:manager) { find_or_create :disclosure_bmt_user }
        let(:info_held) { find_or_create :info_status, :not_held }
        let(:date_responded) { 3.days.ago }
        let(:params) {
          {
            id: internal_review.id,
            foi: {
              date_responded_dd: date_responded.day,
              date_responded_mm: date_responded.month,
              date_responded_yyyy: date_responded.year,
              info_held_status_abbreviation: info_held.abbreviation,
              appeal_outcome_name: appeal_outcome.name,
            }
          }
        }

        before { sign_in manager }

        it "closes a case that has been responded to" do
          patch :process_closure, params: params
          internal_review.reload

          expect(internal_review.current_state).to eq 'closed'
          expect(internal_review.appeal_outcome_id).to eq appeal_outcome.id
          expect(internal_review.date_responded).to eq 3.days.ago.to_date
        end
      end
    end

    describe '#process_date_responded' do
      let(:kase) { create :responded_case, creation_time: 6.business_days.ago }

      include_examples 'process date responded spec', described_class
    end
  end
end

