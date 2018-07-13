require 'rails_helper'

describe CasesController do
  describe '#new_linked_cases_for' do
    describe 'authentication' do
      let(:sar_case)  { create :sar_case }
      let(:sar_case2) { create :sar_case }
      let(:foi_case)  { create :foi_case }
      let(:foi_case2) { create :foi_case }
      let(:foi)       { find_or_create(:foi_correspondence_type) }
      let(:foi_team)  { create :business_unit,
                               correspondence_type_ids: [foi.id] }
      let(:foi_user)  { create :manager, managing_teams: [foi_team] }

      context 'ico correspondences' do
        before do
          sign_in foi_user
        end

        it "doesn't allow viewing original cases if not authorised" do
          get :new_linked_cases_for, format: :js, params: {
                correspondence_type: 'ico',
                link_type: 'original',
                original_case_number: sar_case.number,
              }

          expect(response).to redirect_to('/')
        end

        it "doesn't allow viewing related cases if not authorised" do
          get :new_linked_cases_for, format: :js, params: {
                correspondence_type: 'ico',
                link_type: 'related',
                original_case_number: foi_case.number,
                related_case_number: foi_case2.number,
                related_case_ids: [sar_case.id],
              }

          expect(response).to redirect_to('/')
        end
      end
    end
  end
end
