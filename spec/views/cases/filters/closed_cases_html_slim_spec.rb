require 'rails_helper'

describe 'cases/filters/closed.html.slim' do
  let!(:case_1) { create :closed_case, received_date: 20.business_days.ago }
  let!(:case_2) { create :closed_case }
  let(:search_query) { build_stubbed :search_query }
  let(:request)         { instance_double ActionDispatch::Request,
                                          path: '/cases/closed',
                                          fullpath: '/cases/closed',
                                          query_parameters: {},
                                          params: {}}
  let(:disclosure_specialist)             { find_or_create :disclosure_specialist }

  before do
    allow(request).to receive(:filtered_parameters).and_return({})
    assign(:homepage_nav_manager, GlobalNavManager.new(disclosure_specialist,
                                                     request,
                                                     Settings.homepage_navigation.pages))
    allow(controller).to receive(:current_user).and_return(disclosure_specialist)
  end

  it 'displays all the cases' do
    cases = Case::Base.closed.most_recent_first.page.decorate
    assign(:cases, cases)
    assign(:query, search_query)
    assign(:action_url, '/cases/closed')
    assign(:current_tab_name, 'closed')
    assign(:maximum_records_for_download, 1000)

    render

    closed_cases_page.load(rendered)
    page = closed_cases_page

    expect(page.page_heading.heading.text).to eq 'Closed cases'
    expect(page.page_heading).to have_no_sub_heading

    expect(page.closed_case_report.table_body.closed_case_rows.size).to eq 2

    row = page.closed_case_report.table_body.closed_case_rows.first
    expect(row.case_number.text).to eq "Case number #{case_1.number}"
    expect(row.subject_name.name.text).to eq case_1.name
    expect(row.subject_name.subject.text).to eq case_1.subject

    row = page.closed_case_report.table_body.closed_case_rows.last
    expect(row.case_number.text).to eq "Case number #{case_2.number}"
    expect(row.subject_name.name.text).to eq case_2.name
    expect(row.subject_name.subject.text).to eq case_2.subject

    expect(page).to have_download_deleted_cases_link
  end

  describe 'pagination' do
    before do
      allow(view).to receive(:policy).and_return(spy('Pundit::Policy'))
    end

    it 'renders the paginator' do
      assign(:cases, Case::Base.none.page.decorate)
      assign(:query, search_query)
      assign(:action_url, '/cases/closed')
      assign(:current_tab_name, 'closed')
      assign(:maximum_records_for_download, 1000)
      render
      expect(response).to have_rendered('kaminari/_paginator')
    end
  end
end
