require "rails_helper"

describe 'cases/sar/_date_responded_form.html.slim' do
  let(:closed_sar) { create :closed_sar }

  it 'renders the close_form partial' do
    assign(:case, closed_sar)
    render(partial: 'cases/sar/close_form',
           locals: { kase: closed_sar.decorate,
                     submit_button: 'Save changes' })
    cases_close_page.load(rendered)

    expect(cases_close_page.date_responded_day.value).to eq closed_sar.date_responded.day.to_s
    expect(cases_close_page.date_responded_month.value).to eq closed_sar.date_responded.month.to_s
    expect(cases_close_page.date_responded_year.value).to eq closed_sar.date_responded.year.to_s
    expect(cases_close_page.submit_button.value).to eq 'Save changes'

    expect(cases_close_page).to have_cancel
  end
end
