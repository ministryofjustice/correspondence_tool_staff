require 'rails_helper'

feature 'a user can see all correspondence on the system' do
  given(:page) { CorrespondenceListPage.new }

  given(:foi_category) { create(:category) }
  given(:foi) do
    create(
      :correspondence,
      name: 'Freddie FOI',
      email: 'freddie.foi@testing.digital.justice.gov.uk',
      message: 'viewing foi details test message',
      category: foi_category,
      topic: 'prisons'
    )
  end
  given(:internal_foi_deadline) do
    DeadlineCalculator.internal_deadline(foi).strftime("%d/%m/%y")
  end
  given(:external_foi_deadline) do
    DeadlineCalculator.external_deadline(foi).strftime("%d/%m/%y")
  end

  given(:gq_category) { create(:category, :gq) }
  given(:gq) do
    create(
      :correspondence,
      name: 'Gina GQ',
      email: 'gina.gq@testing.digital.justice.gov.uk',
      message: 'viewing gq details test message',
      category: gq_category,
      topic: 'prisons'
    )
  end
  given(:internal_gq_deadline) do
    DeadlineCalculator.internal_deadline(gq).strftime("%d/%m/%y")
  end
  given(:external_gq_deadline) do
    DeadlineCalculator.external_deadline(gq).strftime("%d/%m/%y")
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
    expect(foi_row.category.text).to eq 'Freedom of information request'
    expect(foi_row.topic.text).to    eq 'Prisons'
    expect(foi_row.name.text).to     eq 'Freddie FOI'
    expect(foi_row.received.text).to eq today
    expect(foi_row.internal_deadline.text).to eq internal_foi_deadline
    expect(foi_row.external_deadline.text).to eq external_foi_deadline

    gq_row = page.correspondence_list.last
    expect(gq_row.category.text).to eq 'General enquiry'
    expect(gq_row.topic.text).to    eq 'Prisons'
    expect(gq_row.name.text).to     eq 'Gina GQ'
    expect(gq_row.received.text).to eq today
    expect(gq_row.internal_deadline.text).to eq internal_gq_deadline
    expect(gq_row.external_deadline.text).to eq external_gq_deadline
  end
end
