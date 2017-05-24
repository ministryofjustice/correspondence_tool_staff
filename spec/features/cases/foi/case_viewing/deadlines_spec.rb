require 'rails_helper'

feature 'Deadlines:' do
  given(:responder)       { create :responder }
  given(:responding_team) { responder.responding_teams.first }
  given(:non_trigger_foi) { create :accepted_case,
                                   responder: responder,
                                   received_date: Date.parse('21/08/2016') }

  background { login_as responder }

  context 'The external deadline' do

    context 'for non trigger FOI requests' do
      scenario 'is shown in the detail view' do
        Timecop.freeze Date.new(2016, 8, 22) do
          visit "/cases/#{non_trigger_foi.id}"
          expect(page).to have_content('Final deadline')
          expect(page).to have_content('19 Sep')
        end
      end
    end

  end
end
