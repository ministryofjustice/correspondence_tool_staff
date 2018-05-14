require 'rails_helper'

feature 'filtering cases' do

  before(:all) do
    login_as create(:manager)
    @unassigned_case                                            = create :case
    @awaiting_responder_case                                    = create :awaiting_responder_case
    @drafting_case                                              = create :accepted_case
    @awaiting_dispatch_case                                     = create :case_with_response
    @pending_dacu_clearance_case                                = create :pending_dacu_clearance_case
    @unaccepted_pending_dacu_clearance_case                     = create :unaccepted_pending_dacu_clearance_case
    @pending_dacu_clearance_case_flagged_for_press              = create :pending_dacu_clearance_case_flagged_for_press
    @pending_dacu_clearance_case_flagged_for_press_and_private  = create :pending_dacu_clearance_case_flagged_for_press_and_private
    @pending_press_clearance_case                               = create :pending_press_clearance_case
    @pending_private_clearance_case                             = create :pending_private_clearance_case
  end

  after(:all) { DbHousekeeping.clean }

  before(:each) { sign_in create(:manager) }

  let(:all_case_numbers) do
    case_nos(@unassigned_case,
             @awaiting_responder_case,
             @drafting_case,
             @awaiting_dispatch_case,
             @pending_dacu_clearance_case,
             @unaccepted_pending_dacu_clearance_case,
             @pending_dacu_clearance_case_flagged_for_press,
             @pending_dacu_clearance_case_flagged_for_press_and_private,
             @pending_press_clearance_case,
             @pending_private_clearance_case)
  end

  scenario 'no checkboxes selected before filter applied', js: true do
    open_cases_page.load(timeliness: 'in_time')
    open_cases_page.filter_tab_links.status_tab.click
    open_cases_page.filters.status_filter_panel.apply_filter_button.click
    expect(open_cases_page.case_numbers).to match_array(all_case_numbers)
  end

  scenario 'filter just unassigned cases', js: true do
    open_cases_page.load(timeliness: 'in_time')
    open_cases_page.filter_tab_links.status_tab.click
    open_cases_page.choose_state('unassigned')
    open_cases_page.state_filter.apply_filter_button.click

    expect(open_cases_page.case_numbers).to eq [ @unassigned_case.number ]
  end

  scenario 'filter on unassigned, drafting and awaiting_dispatch cases', js: true do
    open_cases_page.load(timeliness: 'in_time')
    open_cases_page.filter_tab_links.status_tab.click
    open_cases_page.choose_state('unassigned')
    open_cases_page.choose_state('drafting')
    open_cases_page.choose_state('awaiting_dispatch')
    open_cases_page.state_filter.apply_filter_button.click

    expected_case_nos = case_nos(@unassigned_case, @awaiting_dispatch_case, @drafting_case)
    expect(open_cases_page.case_numbers).to match_array(expected_case_nos)
  end

  scenario 'just pending dacu clearance', js: true do
    open_cases_page.load(timeliness: 'in_time')
    open_cases_page.filter_tab_links.status_tab.click
    open_cases_page.choose_state('pending_dacu_clearance')
    open_cases_page.state_filter.apply_filter_button.click

    expected_case_nos = case_nos(@pending_dacu_clearance_case,
                                 @unaccepted_pending_dacu_clearance_case,
                                 @pending_dacu_clearance_case_flagged_for_press,
                                 @pending_dacu_clearance_case_flagged_for_press_and_private)

    expect(open_cases_page.case_numbers).to match_array(expected_case_nos)
  end

  scenario 'filter, show case detail, all cases produces blank filter selection and all cases', js: true do
    # open case page should show all cases
    open_cases_page.load(timeliness: 'in_time')
    expect(open_cases_page.case_numbers).to match_array(all_case_numbers)

    # filter on unassigned should show just one case
    open_cases_page.filter_tab_links.status_tab.click
    open_cases_page.choose_state('unassigned')
    open_cases_page.state_filter.apply_filter_button.click
    expect(open_cases_page.case_numbers).to eq [ @unassigned_case.number ]

    # clicking on that case number should show the detail of that case
    open_cases_page.case_list.first.number.click
    expect(cases_show_page).to be_displayed

    # clicking on All open cases should redisplay the open cases page with no filter
    cases_show_page.primary_navigation.all_links.first.click
    expect(open_cases_page).to be_displayed
    expect(open_cases_page.case_numbers).to match_array(all_case_numbers)
  end


  def case_nos(*args)
    result = []
    args.each do |kase|
      result << kase.number
    end
    result
  end


end
