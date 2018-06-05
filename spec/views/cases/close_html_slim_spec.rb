require "rails_helper"

describe 'cases/close.html.slim' do
  context 'with an FOI case' do
    let(:foi_being_drafted) { create :case_being_drafted }

    it 'renders the close_form partial' do
      assign(:case, foi_being_drafted.decorate)
      render
      expect(response)
        .to have_rendered(
              partial: 'cases/foi/close_form',
              locals: {
                kase: foi_being_drafted,
                form_url: process_closure_case_path(id: foi_being_drafted.id),
                submit_button: 'Close case'
              }
            )
    end
  end

  context 'with a SAR case' do
    let(:sar_being_drafted) { create :sar_being_drafted }

    it 'renders the close_form partial' do
      assign(:case, sar_being_drafted.decorate)
      render
      expect(response)
        .to have_rendered(
              partial: 'cases/sar/close_form',
              locals: {
                kase: sar_being_drafted,
                form_url: process_closure_case_path(id: sar_being_drafted.id),
                submit_button: 'Close case'
              }
            )
    end

    it 'does not set the value for missing_info' do
      assign(:case, sar_being_drafted.decorate)
      render
      cases_close_page.load(rendered)
      expect(cases_close_page.missing_info.yes).not_to be_checked
      expect(cases_close_page.missing_info.no ).not_to be_checked
    end
  end
end
