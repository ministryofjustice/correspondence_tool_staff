require "rails_helper"

describe 'cases/sar/_close_form.html.slim' do
  let(:closed_sar) { create :closed_sar }

  it 'renders the close_form partial' do
    render(partial: 'cases/sar/close_form.html.slim',
           locals: { kase: closed_sar.decorate,
                     form_url: update_closure_case_path(id: closed_sar.id),
                     submit_button: 'Save changes' })
    cases_close_page.load(rendered)

    expect(cases_close_page.date_responded_day.value).to eq closed_sar.date_responded.day.to_s
    expect(cases_close_page.date_responded_month.value).to eq closed_sar.date_responded.month.to_s
    expect(cases_close_page.date_responded_year.value).to eq closed_sar.date_responded.year.to_s
    expect(cases_close_page.missing_info.no).to be_checked
    expect(cases_close_page.submit_button.value).to eq 'Save changes'
  end
end
