require 'rails_helper'

feature 'Deadlines:' do

  background { login_as create(:user) }

  given(:non_trigger_foi) { create(:correspondence, received_date: Date.parse('21/08/2016')) }
  given(:trigger_foi)     { create(:correspondence, received_date: Date.parse('21/08/2016'), properties: { trigger: true }) }
  given(:gq)              { create(:correspondence, received_date: Date.parse('21/08/2016'), category: create(:category, :gq)) }

  context 'The internal deadline' do

    context 'for General Enquiries' do
      scenario 'is shown in the detail view' do
        visit "/correspondence/#{gq.id}"
        expect(page).to have_content('Draft due')
        expect(page).to have_content('05 Sep')
      end
    end

    context 'for trigger FOI requests' do
      scenario 'is shown in the detail view' do
        visit "/correspondence/#{trigger_foi.id}"
        expect(page).to have_content('Draft due')
        expect(page).to have_content('05 Sep')
      end
    end

    context 'for non_trigger FOI requests' do
      scenario 'is not shown in the detail view' do
        visit "/correspondence/#{non_trigger_foi.id}"
        expect(page).not_to have_content('Draft due')
      end
    end
  end

  context 'The external deadline' do

    context 'for General Enquiries' do
      scenario 'is shown in the detail view' do
        visit "/correspondence/#{gq.id}"
        expect(page).to have_content('Target')
        expect(page).to have_content('12 Sep')
      end
    end

    context 'for trigger FOI requests' do
      scenario 'is shown in the detail view' do
        visit "/correspondence/#{trigger_foi.id}"
        expect(page).to have_content('Target')
        expect(page).to have_content('19 Sep')
      end
    end

    context 'for non trigger FOI requests' do
      scenario 'is shown in the detail view' do
        visit "/correspondence/#{non_trigger_foi.id}"
        expect(page).to have_content('Target')
        expect(page).to have_content('19 Sep')
      end
    end

  end
end
