require 'rails_helper'

feature 'Deadlines:' do
  given(:responder)       { create :responder }
  given(:responding_team) { responder.responding_teams.first }
  given(:non_trigger_foi) { create :accepted_case,
                                   responder: responder,
                                   received_date: Date.parse('21/08/2016') }
  # given(:trigger_foi)     { create :accepted_case,
  #                                  responder: responder,
  #                                  received_date: Date.parse('21/08/2016'),
  #                                  properties: { trigger: true } }
  # given(:gq)              { create :case,
  #                                  responder: responder,
  #                                  received_date: Date.parse('21/08/2016'),
  #                                  category: create(:category, :gq) }

  background { login_as responder }

  context 'The external deadline' do

    # context 'for General Enquiries' do
    #   scenario 'is shown in the detail view' do
    #     visit "/cases/#{gq.id}"
    #     expect(page).to have_content('External deadline')
    #     expect(page).to have_content('12 Sep')
    #   end
    # end

    # context 'for trigger FOI requests' do
    #   scenario 'is shown in the detail view' do
    #     visit "/cases/#{trigger_foi.id}"
    #     expect(page).to have_content('External deadline')
    #     expect(page).to have_content('19 Sep')
    #   end
    # end

    context 'for non trigger FOI requests' do
      scenario 'is shown in the detail view' do
        visit "/cases/#{non_trigger_foi.id}"
        expect(page).to have_content('Final deadline')
        expect(page).to have_content('19 Sep')
      end
    end

  end
end
