require 'rails_helper'

feature 'viewing details of correspondence in the system' do
  given(:page) { CorrespondenceDetailsPage.new }

  given(:gq_category) { create(:category, :gq) }
  given(:gq) do
    create(
      :correspondence,
      name: 'Gina GQ',
      email: 'gina.gq@testing.digital.justice.gov.uk',
      message: 'viewing gq details test message',
      category: gq_category
    )
  end
  given(:internal_gq_deadline) do
    DeadlineCalculator.internal_deadline(gq).strftime("%d %b")
  end
  given(:external_gq_deadline) do
    DeadlineCalculator.external_deadline(gq).strftime("%d %b")
  end

  background do
    login_as create(:user)
  end

  scenario 'when the correspondence is a general enquiry' do
    page.load id: gq.id
    expect(page.correspondent_name).to have_content('Gina GQ')
    expect(page.correspondent_email).to have_content('gina.gq@testing.digital.justice.gov.uk')
    expect(page.message).to have_content('viewing gq details test message')
    expect(page.category).to have_content(gq_category.name)
    expect(page.internal_deadline).to have_content(internal_gq_deadline)
    expect(page.external_deadline).to have_content(external_gq_deadline)
    expect(page.status).to have_content(gq.state.humanize)
  end

  given(:foi_category) { create(:category) }
  given(:foi) do
    create(
      :correspondence,
      name: 'Freddie FOI',
      email: 'freddie.foi@testing.digital.justice.gov.uk',
      message: 'viewing foi details test message',
      category: foi_category
    )
  end
  given(:internal_foi_deadline) do
    DeadlineCalculator.internal_deadline(foi).strftime("%d/%m/%y")
  end
  given(:external_foi_deadline) do
    DeadlineCalculator.external_deadline(foi).strftime("%d/%m/%y")
  end

  scenario 'when the correspondence is a foi request' do
    page.load id: foi.id
    expect(page.correspondent_name).to have_content('Freddie FOI')
    expect(page.correspondent_email).to have_content('freddie.foi@testing.digital.justice.gov.uk')
    expect(page.message).to have_content('viewing foi details test message')
    expect(page.category).to have_content(foi_category.name)
    expect(page.internal_deadline).to have_content(foi.internal_deadline.strftime('%d %b'))
    expect(page.external_deadline).to have_content(foi.external_deadline.strftime('%d %b'))
    expect(page.status).to have_content(foi.state.humanize)
  end
end
