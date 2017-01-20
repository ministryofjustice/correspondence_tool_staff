require 'rails_helper'

feature 'a user can see all case on the system' do
  given(:page) { CaseListPage.new }

  given(:foi_category) { create(:category) }
  given(:non_trigger_foi) do
    create(
      :assigned_case,
      name: 'Freddie FOI',
      email: 'freddie.foi@testing.digital.justice.gov.uk',
      subject: 'test FOI subject',
      message: 'viewing foi details test message',
      category: foi_category
    )
  end

  given(:gq_category) { create(:category, :gq) }
  given(:gq) do
    create(
      :assigned_case,
      name: 'Gina GQ',
      email: 'gina.gq@testing.digital.justice.gov.uk',
      subject: 'test GQ subject',
      message: 'viewing gq details test message',
      category: gq_category
    )
  end

  background do
    # Create our cases
    non_trigger_foi
    gq

    login_as create(:user)
  end

  scenario 'when a non-trigger FOI and a GQ have been received' do
    visit '/'
    expect(page.case_list.count).to eq 2

    non_trigger_foi_row = page.case_list.last
    expect(non_trigger_foi_row.name.text).to     eq 'Freddie FOI'
    expect(non_trigger_foi_row.subject.text).to  eq 'test FOI subject'
    expect(non_trigger_foi_row.external_deadline.text).to have_content(non_trigger_foi.external_deadline.strftime('%e %b %Y'))
    expect(non_trigger_foi_row.number).to have_link("#{non_trigger_foi.number}", href: Rails.root.join("/cases/#{non_trigger_foi.id}"))
    expect(non_trigger_foi_row.status.text).to eq 'Waiting to be accepted'

    gq_row = page.case_list.first
    expect(gq_row.name.text).to     eq 'Gina GQ'
    expect(gq_row.subject.text).to  eq 'test GQ subject'
    expect(gq_row.external_deadline.text).to have_content(gq.external_deadline.strftime('%e %b %Y'))
    expect(gq_row.number).to have_link("#{gq.number}", href: Rails.root.join("/cases/#{gq.id}"))
    expect(gq_row.status.text).to eq 'Waiting to be accepted'
  end
end
