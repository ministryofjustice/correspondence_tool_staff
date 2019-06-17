require 'rails_helper'

RSpec.describe Cases::ClosuresController, type: :controller do
  let(:manager) { find_or_create :disclosure_specialist_bmt }
  let(:responder) { find_or_create :foi_responder }
  let(:responding_team) { responder.responding_teams.first }
  let(:responded_case) {
    create(
      :responded_case,
      responder: responder,
      responding_team: responding_team,
      received_date: 5.days.ago
    )
  }


  context "as an authenticated manager" do
    before { sign_in manager }

    describe '#close' do
      it 'displays the process close page' do
        get :close, params: { case_id: responded_case.id }
        expect(response).to render_template(:close)
      end
    end

    describe '#process_closure' do
      let(:outcome)     { find_or_create :outcome, :requires_refusal_reason }
      let(:info_held)   { find_or_create :info_status, :held }

      it 'authorizes using can_close_case?' do
        expect{
          patch :process_closure, params: case_closure_params(responded_case)
        }.to require_permission(:can_close_case?)
          .with_args(manager, responded_case)
      end

      it "closes a case that has been responded to" do
        patch :process_closure, params: case_closure_params(responded_case)
        expect(Case::Base.first.current_state).to eq 'closed'
        expect(Case::Base.first.outcome_id).to eq outcome.id
        expect(Case::Base.first.date_responded).to eq 3.days.ago.to_date
      end

      def case_closure_params(kase)
        date_responded = 3.days.ago
        {
          id: kase.id,
          case_foi: {
            date_responded_dd: date_responded.day,
            date_responded_mm: date_responded.month,
            date_responded_yyyy: date_responded.year,
            info_held_status_abbreviation: info_held.abbreviation,
            outcome_abbreviation: outcome.abbreviation,
            # refusal_reason_name: refusal_reason.name,
          }
        }
      end

      context 'FOI internal review' do
        let(:appeal_outcome)    { find_or_create :appeal_outcome, :upheld }
        let(:info_held)         { find_or_create :info_status, :not_held }
        let(:internal_review)   { create :responded_compliance_review }

        it "closes a case that has been responded to" do
          patch :process_closure, params: case_closure_params(internal_review)
          expect(Case::Base.first.current_state).to eq 'closed'
          expect(Case::Base.first.appeal_outcome_id).to eq appeal_outcome.id
          expect(Case::Base.first.date_responded).to eq 3.days.ago.to_date
        end

        def case_closure_params(internal_review)
          date_responded = 3.days.ago
          {
            id: internal_review.id,
            case_foi: {
              date_responded_dd: date_responded.day,
              date_responded_mm: date_responded.month,
              date_responded_yyyy: date_responded.year,
              info_held_status_abbreviation: info_held.abbreviation,
              appeal_outcome_name: appeal_outcome.name
            }
          }
        end
      end

      context 'SAR' do
        let(:responder)   { sar.responder }
        let(:sar)         { create :accepted_sar }

        before(:all) do
          CaseClosure::MetadataSeeder.seed!
        end

        after(:all) do
          CaseClosure::MetadataSeeder.unseed!
        end

        before do
          allow(ActionNotificationsMailer).to receive_message_chain(:notify_team,
            :deliver_later)
        end

        it "closes a case that has been responded to" do
          sign_in responder
          patch :process_respond_and_close, params: sar_closure_params(sar)
          expect(Case::SAR.first.current_state).to eq 'closed'
          expect(Case::SAR.first.refusal_reason_id).to eq CaseClosure::RefusalReason.sar_tmm.id
          expect(Case::SAR.first.date_responded).to eq 3.days.ago.to_date
          expect(ActionNotificationsMailer)
            .to have_received(:notify_team)
              .with(sar.managing_team, sar, 'Case closed')
        end

        context 'not the assigned responder' do
          it "does not progress the case" do
            sign_in another_responder
            patch :process_respond_and_close, params: sar_closure_params(sar)
            expect(Case::SAR.first.current_state).to eq 'drafting'
            expect(Case::SAR.first.date_responded).to be nil
            expect(ActionNotificationsMailer)
              .not_to have_received(:notify_team)
                .with(sar.managing_team, sar, 'Case closed')
          end
        end

        def sar_closure_params(sar)
          date_responded = 3.days.ago
          {
            id: sar.id,
            case_sar: {
              date_responded_dd: date_responded.day,
              date_responded_mm: date_responded.month,
              date_responded_yyyy: date_responded.year,
              missing_info: 'yes'
            }
          }
        end
      end
    end
  end
end
