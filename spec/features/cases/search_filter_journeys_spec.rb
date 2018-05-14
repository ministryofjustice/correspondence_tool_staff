require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
require File.join(Rails.root, 'spec', 'site_prism', 'support', 'helper_methods')


feature 'filters whittle down search results' do
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
  end

  context 'status filter' do
    scenario 'filter by status: open', js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 8)
      cases_search_page.filter_on('status', 'status_open')
      expect(cases_search_page.case_numbers).to match_array expected_case_numbers(:std_draft_foi,
                                                                                  :trig_responded_foi,
                                                                                  :std_unassigned_irc,
                                                                                  :std_unassigned_irt)

      cases_search_page.open_filter(:status)
      expect(cases_search_page.status_filter_panel.open_checkbox)
        .to be_checked

      cases_search_page.filter_crumb_for('Open').click

      expect(cases_search_page.case_numbers)
        .to match_array expected_case_numbers(*@all_cases)
      cases_search_page.open_filter(:status)
      expect(cases_search_page.status_filter_panel.open_checkbox)
        .not_to be_checked
      expect(cases_search_page.filter_crumb_for('Open'))
        .not_to be_present
    end
  end


  context 'type filter' do
    scenario 'filter by internal review for compliance, timeliness', js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 8)
      cases_search_page.filter_on('type', 'case_type_foi-ir-compliance', 'case_type_foi-ir-timeliness')
      expect(cases_search_page.case_numbers).to match_array expected_case_numbers( :std_unassigned_irc,
                                                                                   :std_unassigned_irt,
                                                                                   :std_closed_irc,
                                                                                   :std_closed_irt)

      cases_search_page.open_filter(:type)
      expect(cases_search_page.type_filter_panel.foi_ir_compliance_checkbox)
        .to be_checked
      expect(cases_search_page.type_filter_panel.foi_ir_timeliness_checkbox)
        .to be_checked

      crumb_text = 'FOI - Internal review for compliance + 1 more'
      cases_search_page.filter_crumb_for(crumb_text).click

      expect(cases_search_page.case_numbers)
        .to match_array expected_case_numbers(*@all_cases)
      cases_search_page.open_filter(:type)
      expect(cases_search_page.type_filter_panel.foi_ir_compliance_checkbox)
        .not_to be_checked
      expect(cases_search_page.type_filter_panel.foi_ir_timeliness_checkbox)
        .not_to be_checked
      expect(cases_search_page.filter_crumb_for(crumb_text))
        .not_to be_present
    end

    scenario 'filter by standard FOI and trigger', js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 8)
      cases_search_page.filter_on('type', 'case_type_foi-standard', 'sensitivity_trigger')
      expect(cases_search_page.case_numbers).to match_array expected_case_numbers( :trig_responded_foi, :trig_closed_foi)

      cases_search_page.open_filter(:type)
      expect(cases_search_page.type_filter_panel.foi_standard_checkbox)
        .to be_checked
      expect(cases_search_page.type_filter_panel.foi_trigger_checkbox)
        .to be_checked

      expect(cases_search_page.filter_crumb_for('FOI - Standard')).to be_present
      cases_search_page.filter_crumb_for('Trigger').click

      expect(cases_search_page.case_numbers)
        .to match_array expected_case_numbers(:trig_responded_foi,
                                              :trig_closed_foi,
                                              :std_draft_foi,
                                              :std_closed_foi)
      cases_search_page.open_filter(:type)
      expect(cases_search_page.type_filter_panel.foi_standard_checkbox)
        .to be_checked
      expect(cases_search_page.filter_crumb_for('Trigger'))
        .not_to be_present

      cases_search_page.filter_crumb_for('FOI - Standard').click

      expect(cases_search_page.case_numbers)
        .to match_array expected_case_numbers(*@all_cases)
      cases_search_page.open_filter(:type)
      expect(cases_search_page.type_filter_panel.foi_standard_checkbox)
        .not_to be_checked
      expect(cases_search_page.filter_crumb_for('FOI - Standard'))
        .not_to be_present

    end

    scenario 'selecting both sensitivies then going back and unchecking one of them' do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 8)
      cases_search_page.filter_on('type', 'sensitivity_non-trigger', 'sensitivity_trigger')

      expect(cases_search_page.case_numbers).to match_array expected_case_numbers(  :std_draft_foi,
                                                                                    :std_closed_foi,
                                                                                    :trig_responded_foi,
                                                                                    :trig_closed_foi,
                                                                                    :std_unassigned_irc,
                                                                                    :std_unassigned_irt,
                                                                                    :std_closed_irc,
                                                                                    :std_closed_irt)

      expect(cases_search_page.filter_crumb_for('Non-trigger + 1 more'))
        .to be_present

      # Now uncheck non-trigger
      cases_search_page.remove_filter_on('type', 'sensitivity_non-trigger')
      expect(cases_search_page.case_numbers).to  match_array expected_case_numbers( :trig_responded_foi,
                                                                                    :trig_closed_foi)


    end
  end


  context 'exemptions filter', js: true do
    before do
      @ex1 = create_case_with_exemptions(%w{ s21 s22 s23 })
      @ex2 = create_case_with_exemptions(%w{ s27 s22 s40 })
      @ex4 = create_case_with_exemptions(%w{ s40 })
      Case::Base.update_all_indexes
    end

    context 'specifying one exemtpion' do
      scenario 'selects all cases closed with that exemption', js: true do
        login_step user: @setup.disclosure_bmt_user
        search_for(search_phrase: 'prison guards', num_expected_results: 11)
        cases_search_page.filter_on_exemptions(common: %w{ s40 } )
        expect(cases_search_page.case_numbers).to match_array [ @ex2.number, @ex4.number ]

        cases_search_page.open_filter(:exemption)

        exemption_filter_panel = cases_search_page.exemption_filter_panel
        expect(exemption_filter_panel.most_used.checkbox_for(:s40))
          .to be_checked
        expect(exemption_filter_panel.exemption_all.checkbox_for(:s40))
          .to be_checked

        cases_search_page.filter_crumb_for('(s40) - Personal information').click
        cases_search_page.open_filter(:exemption)

        exemption_filter_panel = cases_search_page.exemption_filter_panel
        expect(exemption_filter_panel.most_used.checkbox_for(:s40))
          .not_to be_checked
        expect(exemption_filter_panel.exemption_all.checkbox_for(:s40))
          .not_to be_checked
      end
    end

    context 'specifying multiple exemptions', js: true do
      scenario 'selects only cases that match ALL specified exemption' do
        login_step user: @setup.disclosure_bmt_user
        search_for(search_phrase: 'prison guards', num_expected_results: 11)
        cases_search_page.filter_on_exemptions(common: %w{ s21 s22 } )
        expect(cases_search_page.case_numbers).to match_array [ @ex1.number  ]

        cases_search_page.open_filter(:exemption)

        exemption_filter_panel = cases_search_page.exemption_filter_panel
        expect(exemption_filter_panel.most_used.checkbox_for(:s21))
          .to be_checked
        expect(exemption_filter_panel.most_used.checkbox_for(:s22))
          .to be_checked
        expect(exemption_filter_panel.exemption_all.checkbox_for(:s21))
          .to be_checked
        expect(exemption_filter_panel.exemption_all.checkbox_for(:s22))
          .to be_checked

        s21_plus_one = '(s21) - Information accessible by other means + 1 more'
        expect(cases_search_page.filter_crumb_for(s21_plus_one)).to be_present
      end
    end
  end


  context 'assigned business unit filter', js: true do
    it 'returns cases assigned to the specified business units' do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 8)
      cases_search_page.filter_tab_links.assigned_to_tab.click
      cases_search_page.assigned_to_filter_panel.business_unit_search_term.set('main')
      cases_search_page.assigned_to_filter_panel.main_responding_team_checkbox.click
      cases_search_page.assigned_to_filter_panel.apply_filter_button.click

      expect(cases_search_page.case_numbers).to match_array expected_case_numbers(:std_draft_foi,
                                                                                  :trig_responded_foi,
                                                                                  :trig_closed_foi)

      cases_search_page.open_filter(:assigned_to)
      main_team_name = 'Main responding_team'
      assigned_to_filter_panel = cases_search_page.assigned_to_filter_panel
      expect(assigned_to_filter_panel.checkbox_for(main_team_name))
        .to be_checked

      cases_search_page.filter_crumb_for(main_team_name).click

      cases_search_page.open_filter(:assigned_to)
      main_team_name = 'Main responding_team'
      assigned_to_filter_panel = cases_search_page.assigned_to_filter_panel
      expect(assigned_to_filter_panel.checkbox_for(main_team_name))
        .not_to be_checked
      expect(cases_search_page.filter_crumb_for(main_team_name)).not_to be_present
    end
  end

  context 'all filters set' do
    before do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 8)

      cases_search_page.filter_on('status', 'status_open')
      cases_search_page.filter_on('type', 'case_type_foi-standard', 'sensitivity_trigger')

      cases_search_page.filter_on_exemptions(common: %w{ s40 } )

      cases_search_page.filter_tab_links.assigned_to_tab.click
      cases_search_page.assigned_to_filter_panel.business_unit_search_term.set('main')
      cases_search_page.assigned_to_filter_panel.main_responding_team_checkbox.click
      cases_search_page.assigned_to_filter_panel.apply_filter_button.click

      cases_search_page.filter_on_deadline('Today')

      @s40_exemption = '(s40) - Personal information'
      @from_to_date = "#{I18n.l Date.today} - #{I18n.l Date.today}"
    end

    scenario 'clearing individual filters', js: true do
      cases_search_page.filter_crumb_for('Open').click

      expect(cases_search_page.filter_crumb_for('Open'                )).not_to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).to be_present

      cases_search_page.filter_crumb_for('FOI - Standard').click

      expect(cases_search_page.filter_crumb_for('Open'                )).not_to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).to be_present

      cases_search_page.filter_crumb_for('Trigger').click

      expect(cases_search_page.filter_crumb_for('Open'                )).not_to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).not_to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).to be_present

      cases_search_page.filter_crumb_for(@s40_exemption).click

      expect(cases_search_page.filter_crumb_for('Open'                )).not_to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).not_to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).to be_present

      cases_search_page.filter_crumb_for('Main responding_team').click

      expect(cases_search_page.filter_crumb_for('Open'                )).not_to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).not_to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).not_to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).to be_present

      cases_search_page.filter_on('status', 'status_open')
      cases_search_page.filter_crumb_for(@from_to_date).click

      expect(cases_search_page.filter_crumb_for('Open'                )).to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).not_to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).not_to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).not_to be_present
    end

    scenario 'clearing all filters', js: true do
      expect(cases_search_page.filter_crumb_for('Open'                )).to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).to be_present

      cases_search_page.click_on 'Clear all filters'

      expect(cases_search_page.filter_crumb_for('Open'                )).not_to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).not_to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).not_to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).not_to be_present
    end
  end

  def expected_case_numbers(*case_names)
    case_names.map{ |name| @setup.__send__(name) }.map(&:number)
  end

  def create_case_with_exemptions(exemption_codes)
    exemptions = []
    exemption_codes.each do |code|
      exemptions << CaseClosure::Exemption.__send__(code)
    end
    create :closed_case,
           subject: "Prison guards #{exemption_codes.join(',')}",
           info_held_status: find_or_create(:info_status, :held),
           outcome: find_or_create(:outcome, :refused),
           exemptions: exemptions
  end
end

