require 'rails_helper'

feature 'viewing details of case in the system' do
  given(:page) { CaseDetailsPage.new }

  background do
    login_as create(:user)
  end

  given(:gq_category) { create(:category, :gq) }
  given(:gq) do
    create(
      :assigned_case,
      requester_type: :journalist,
      name: 'Gina GQ',
      email: 'gina.gq@testing.digital.justice.gov.uk',
      subject: 'this is a gq',
      message: 'viewing gq details test message',
      category: gq_category
    )
  end

  given(:internal_gq_deadline) do
    DeadlineCalculator.internal_deadline(gq).strftime("%e %b %Y")
  end
  given(:external_gq_deadline) do
    DeadlineCalculator.external_deadline(gq).strftime("%e %b %Y")
  end

  scenario 'when the case is a general enquiry' do
    page.load id: gq.id

    expect(page).to have_case_heading
    expect(page.case_heading.case_number).to have_content(gq.number)
    expect(page.case_heading).to have_content(gq.subject)

    expect(page).to have_no_escalation_notice

    expect(page).to have_sidebar
    expect(page.sidebar).to have_external_deadline
    expect(page.sidebar.external_deadline).
      to have_content(external_gq_deadline)
    expect(page.sidebar.status).to have_content('Waiting to be accepted')
    expect(page.sidebar.name).to have_content('Gina GQ')
    expect(page.sidebar.requester_type).
      to have_content(gq.requester_type.humanize)
    expect(page.sidebar.email).
      to have_content('gina.gq@testing.digital.justice.gov.uk')
    expect(page.sidebar.postal_address).to have_content(gq.postal_address)

    expect(page.message).to have_content('viewing gq details test message')
    expect(page.received_date).to have_content(foi_received_date)
  end

  given(:foi_category) { create(:category) }
  given(:foi) do
    create(
      :assigned_case,
      requester_type: :offender,
      name: 'Freddie FOI',
      email: 'freddie.foi@testing.digital.justice.gov.uk',
      subject: 'this is a foi',
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

  given(:foi_received_date) do
    foi.received_date.strftime("%e %b %Y")
  end
  given(:foi_escalation_deadline) do
    DeadlineCalculator.escalation_deadline(foi).strftime("%e %b %Y")
  end
  given(:external_foi_deadline) do
    DeadlineCalculator.external_deadline(foi).strftime("%e %b %Y")
  end


  context 'when the case is a non-trigger foi request' do
    scenario 'displays all case content ' do
      page.load id: foi.id

      expect(page).to have_case_heading
      expect(page.case_heading.case_number).to have_content(foi.number)
      expect(page.case_heading.text).to have_content(foi.subject)

      expect(page).to have_sidebar
      expect(page.sidebar).to have_external_deadline
      expect(page.sidebar.external_deadline).
        to have_content(external_foi_deadline)
      expect(page.sidebar.status).to have_content('Waiting to be accepted')
      expect(page.sidebar.name).to have_content('Freddie FOI')
      expect(page.sidebar.requester_type).
        to have_content(foi.requester_type.humanize)
      expect(page.sidebar.email).
        to have_content('freddie.foi@testing.digital.justice.gov.uk')
      expect(page.sidebar.postal_address).to have_content(foi.postal_address)

      expect(page.message).to have_content('viewing foi details test message')
      expect(page.received_date).to have_content(foi_received_date)
    end

    scenario 'User views the case while its within "Day 6"' do
      page.load id: foi.id
      expect(page).to have_escalation_notice
      expect(page.escalation_notice).to have_text(foi_escalation_deadline)
    end

    scenario 'User views the case that is outside "Day 6" ' do
      page.load id: old_foi.id
      expect(page).to have_no_escalation_notice
    end
  end
end
