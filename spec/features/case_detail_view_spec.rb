require 'rails_helper'

feature 'viewing details of case in the system' do
  given(:page) { CaseDetailsPage.new }

  given(:gq_category) { create(:category, :gq) }
  given(:gq) do
    create(
      :case,
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

  scenario 'when the case is a general enquiry' do
    page.load id: gq.id
    expect(page).to have_no_escalation_notice
    expect(page.correspondent_name).to have_content('Gina GQ')
    expect(page.correspondent_email).to have_content('gina.gq@testing.digital.justice.gov.uk')
    expect(page.message).to have_content('viewing gq details test message')
    expect(page.category).to have_content(gq_category.name)
    expect(page.external_deadline).to have_content(external_gq_deadline)
    expect(page.status).to have_content(gq.state.humanize)
  end

  given(:foi_category) { create(:category) }
  given(:foi) do
    create(
      :case,
      name: 'Freddie FOI',
      email: 'freddie.foi@testing.digital.justice.gov.uk',
      message: 'viewing foi details test message',
      category: foi_category
    )
  end

  given(:old_foi) do
    create(
      :case,
      received_date: 31.days.ago,
      category: foi_category
    )
  end

  given(:foi_escalation_deadline) do
    DeadlineCalculator.escalation_deadline(foi).strftime("%d/%m/%y")
  end
  given(:external_foi_deadline) do
    DeadlineCalculator.external_deadline(foi).strftime("%d/%m/%y")
  end

  context 'when the case is a non-trigger foi request' do
    scenario 'displays all case content ' do
      page.load id: foi.id
      expect(page.correspondent_name).to have_content('Freddie FOI')
      expect(page.correspondent_email).to have_content('freddie.foi@testing.digital.justice.gov.uk')
      expect(page.message).to have_content('viewing foi details test message')
      expect(page.category).to have_content(foi_category.name)
      expect(page.escalation_deadline).to have_content(foi.escalation_deadline.strftime('%d %b'))
      expect(page.external_deadline).to have_content(foi.external_deadline.strftime('%d %b'))
      expect(page.status).to have_content(foi.state.humanize)
    end

    scenario 'User views the case while its within "Day 6"' do
      page.load id: foi.id
      expect(page).to have_escalation_notice
      expect(page.escalation_notice).to have_text(foi.escalation_deadline.strftime('%d %B'))
    end

    scenario 'User views the case that is outside "Day 6" ' do
      page.load id: old_foi.id
      expect(page).to have_no_escalation_notice
    end
  end
end
