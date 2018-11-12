require "rails_helper"
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

feature 'filtering by assigned business unit' do
  include Features::Interactions
  include PageObjects::Pages::Support

  before(:all) do
    CaseClosure::MetadataSeeder.seed!(verbose: false)

    @all_cases = [
        :std_draft_foi,
        :std_closed_foi,
        :trig_responded_foi,
        :trig_closed_foi,
        :std_unassigned_irc,
        :std_unassigned_irt,
        :std_closed_irc,
        :std_closed_irt
    ]

    @setup = StandardSetup.new(only_cases: @all_cases)

    @open_cases = [
        @setup.std_draft_foi,
        @setup.trig_responded_foi,
        @setup.std_unassigned_irc,
        @setup.std_unassigned_irt,
    ]

    # add a common search term to them all
    #
    @setup.cases.each do | _kase_name, kase |
      kase.subject += ' prison guards'
      kase.save!
    end
    Case::Base.update_all_indexes
  end


  after(:all) do
    DbHousekeeping.clean
    Timecop.return
  end

  context 'from search page' do

    before(:each) do
      login_as @setup.disclosure_bmt_user
      cases_search_page.load
      search_for_phrase(page: cases_search_page,
                        search_phrase: 'prison guards',
                        num_expected_results: 8)
    end

    it 'returns cases assigned to the specified business units', js: true do
      expected_cases = [:std_closed_foi,
                        :std_closed_irc,
                        :std_closed_irt,
                        :std_draft_foi,
                        :trig_responded_foi,
                        :trig_closed_foi]
      filter_and_check_results(cases_search_page, expected_cases)
    end
  end

  context 'from open cases page' do
    before(:each) do
      login_as @setup.disclosure_bmt_user
      open_cases_page.load
      cases = open_cases_page.case_list
      expect(cases.count).to eq @open_cases.size
    end

    it 'returns open cases assigned to the specified business unit', js: true do
      expected_cases = [:std_draft_foi, :trig_responded_foi]
      filter_and_check_results(open_cases_page, expected_cases)
    end
  end

  def filter_and_check_results(page, expected_cases)
    page.filter_tab_links.assigned_to_tab.click
    page.assigned_to_filter_panel.business_unit_search_term.set('foi')
    page.assigned_to_filter_panel.foi_responding_team_checkbox.click
    page.assigned_to_filter_panel.apply_filter_button.click

    expect(page.case_numbers).to match_array expected_case_numbers(*expected_cases)

    page.open_filter(:assigned_to)
    main_team_name = 'FOI Responding Team'
    assigned_to_filter_panel = page.assigned_to_filter_panel
    expect(assigned_to_filter_panel.checkbox_for(main_team_name))
        .to be_checked
    page.filter_crumb_for(main_team_name).click

    page.open_filter(:assigned_to)
    assigned_to_filter_panel = page.assigned_to_filter_panel
    expect(assigned_to_filter_panel.checkbox_for(main_team_name))
        .not_to be_checked
    expect(page.filter_crumb_for(main_team_name)).not_to be_present
  end
end

