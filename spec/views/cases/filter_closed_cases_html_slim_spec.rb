require 'rails_helper'

describe 'cases/filter_closed_cases.html.slim' do
  # Must use before(:each) otherwise RSpec complains
  before(:each) do
    assign(:report, Report.new)

    render

    filter_closed_cases_page.load(rendered)
    @page = filter_closed_cases_page
  end

  describe 'page elements' do
    it 'displays labels' do
      expect(@page.page_heading.heading.text).to eq 'Download closed cases'
      expect(@page.page_heading).to have_no_sub_heading
      expect(@page.last_month_link.text).to eq 'Last month'
      expect(@page.submit_button.value).to eq 'Download cases (.csv)'
    end

    describe 'date ranges' do
      it 'displays period start/end date inputs' do
        expect(@page).to have_period_start
        expect(@page).to have_period_end
      end
    end
  end
end
