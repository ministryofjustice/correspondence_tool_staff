require 'rails_helper'

feature 'a user can see all correspondence on the system' do
  given(:page) { CorrespondenceListPage.new }

  given(:foi_category) { create(:category) }
  given(:foi) do
    create(
      :correspondence,
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
      :correspondence,
      name: 'Gina GQ',
      email: 'gina.gq@testing.digital.justice.gov.uk',
      subject: 'test GQ subject',
      message: 'viewing gq details test message',
      category: gq_category
    )
  end

  background do
    # Create our correspondences
    foi
    gq

    login_as create(:user)
  end

  scenario 'when an FOI and a GQ have been received' do
    visit '/'
    expect(page.correspondence_list.count).to eq 2

    today = Time.zone.today.strftime("%d/%m/%y")

    foi_row = page.correspondence_list.first
    expect(foi_row.name.text).to     eq 'Freddie FOI'
    expect(foi_row.subject.text).to  eq 'test FOI subject'
    expect(foi_row.received.text).to eq today

    gq_row = page.correspondence_list.last
    expect(gq_row.name.text).to     eq 'Gina GQ'
    expect(gq_row.subject.text).to  eq 'test GQ subject'
    expect(gq_row.received.text).to eq today
  end
end
