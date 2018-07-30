require 'rails_helper'

describe CasesController do
  describe '#new_linked_cases_for' do
    describe 'authentication' do
      let(:sar_case)      { create :sar_case }
      let(:sar_case2)     { create :sar_case }
      let(:foi_case)      { create :foi_case }
      let(:foi_case2)     { create :foi_case }
      let(:foi)           { find_or_create(:foi_correspondence_type) }

      let(:foi_only_team) { create :business_unit,
                                   correspondence_type_ids: [foi.id] }
      # Case managed by foi-only team.
      let(:foi_only_case) { create :foi_case, managing_team: foi_only_team }
      let(:foi_only_user) { create :manager, managing_teams: [foi_only_team] }
      let(:user)          { find_or_create :disclosure_bmt_user }

      let(:json_response) { JSON.parse(response.body) }

      def new_linked_cases_for_request(additional_params = {})
        get :new_linked_cases_for,
            xhr: true,
            format: :js,
            params: params.merge(additional_params)
      end

      context 'ico correspondences' do
        before do
          sign_in user
        end

        context 'linking original case' do
          let(:params) {
            {
              correspondence_type: 'ico',
              link_type: 'original',
            }
          }

          it 'renders the partial on success' do
            new_linked_cases_for_request(original_case_number: foi_case.number)

            expect(response).to have_http_status 200
            expect(response).to render_template(
                                  "cases/ico/case_linking/_linked_cases"
                                )
            expect(assigns[:linked_cases]).to eq [foi_case]
          end

          it 'returns an error if original_case_number is blank' do
            new_linked_cases_for_request(original_case_number: '')

            expect(response).to have_http_status 400
            expect(json_response['linked_case_error'])
              .to eq 'Enter original case number'
          end

          it "returns an error if original_case_number doesn't exist" do
            new_linked_cases_for_request(original_case_number: 'n283nau')

            expect(response).to have_http_status 400
            expect(json_response['linked_case_error'])
              .to eq 'Original case not found'
          end

          it "doesn't allow linking of case that isn't an FOI or SAR" do
            foi_irt = create(:closed_timeliness_review)
            new_linked_cases_for_request(original_case_number: foi_irt.number)

            expect(response).to have_http_status 400
            expect(json_response['linked_case_error'])
              .to eq 'Original case must be FOI or SAR'
          end

          context 'as a user only allowed to view FOI cases' do
            let(:user) { foi_only_user }

            it "doesn't allow viewing original cases if not authorised" do
              new_linked_cases_for_request(original_case_number: sar_case.number)

              expect(response).to have_http_status 400
              expect(json_response['linked_case_error'])
                .to eq 'Not authorised to view case'
            end
          end
        end

        context 'linking related case' do
          let(:params) {
            {
              correspondence_type: 'ico',
              link_type: 'related',
            }
          }

          it 'renders the partial on success' do
            new_linked_cases_for_request(original_case_number: foi_case.number,
                                         related_case_number: foi_case2.number,
                                         related_case_ids: nil)

            expect(response).to have_http_status 200
            expect(response).to render_template(
                                  "cases/ico/case_linking/_linked_cases"
                                )
            expect(assigns[:linked_cases]).to eq [foi_case2]
          end

          it 'returns an error if related_case_number is blank' do
            new_linked_cases_for_request(original_case_number: foi_case.number,
                                         related_case_number: '')

            expect(response).to have_http_status 400
            expect(json_response['linked_case_error'])
              .to eq 'Enter related case number'
          end

          it "returns an error if related_case_number doesn't exist" do
            new_linked_cases_for_request(original_case_number: foi_case.number,
                                         related_case_number: '2nnahk')

            expect(response).to have_http_status 400
            expect(json_response['linked_case_error'])
              .to eq 'Related case not found'
          end

          it "doesn't allow linking of SAR case to FOI ICO" do
            new_linked_cases_for_request(original_case_number: foi_case.number,
                                         related_case_number: sar_case.number,
                                         related_case_ids: nil)

            expect(response).to have_http_status 400
            expect(json_response['linked_case_error'])
              .to eq "You've linked an FOI case as the original for this " \
                     "appeal. You can now only link other FOI cases or " \
                     "internal reviews as related to this cases."
          end

          it "doesn't allow re-linking of original case as also related case" do
            new_linked_cases_for_request(original_case_number: foi_case.number,
                                         related_case_number: foi_case.number,
                                         related_case_ids: nil)

            expect(response).to have_http_status 400
            expect(json_response['linked_case_error'])
              .to eq "Case is already linked"
          end

          it "doesn't allow re-linking of related case again" do
            new_linked_cases_for_request(original_case_number: foi_case.number,
                                         related_case_number: foi_case2.number,
                                         related_case_ids: foi_case2.id)

            expect(response).to have_http_status 400
            expect(json_response['linked_case_error'])
              .to eq "Case is already linked"
          end

          context 'as a user only allowed to view FOI cases' do
            let(:user) { foi_only_user }

            it "doesn't allow viewing related cases if not authorised" do
              new_linked_cases_for_request(original_case_number: foi_case.number,
                                           related_case_number: sar_case.number,
                                           related_case_ids: nil)

              expect(response).to have_http_status 400
              expect(json_response['linked_case_error'])
                .to eq 'Not authorised to view case'
            end

            it 'removes any existing linked related cases if not authorised' do
              new_linked_cases_for_request(original_case_number: foi_case.number,
                                           related_case_number: foi_case2.number,
                                           related_case_ids: sar_case.number)

              expect(response).to have_http_status 200
              expect(response).to render_template(
                                    "cases/ico/case_linking/_linked_cases"
                                  )
              expect(assigns[:linked_cases]).not_to include(sar_case)
            end
          end
        end
      end
    end
  end
end
