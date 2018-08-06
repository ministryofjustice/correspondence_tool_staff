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
      :std_closed_irt,
      :sar_noff_draft
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
      search_for(search_phrase: 'prison guards', num_expected_results: 9)
      cases_search_page.filter_on('status', 'open')
      expect(cases_search_page.case_numbers).to match_array expected_case_numbers(
                                                              :std_draft_foi,
                                                              :trig_responded_foi,
                                                              :std_unassigned_irc,
                                                              :std_unassigned_irt,
                                                              :sar_noff_draft,
                                                            )

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
      search_for(search_phrase: 'prison guards', num_expected_results: 9)
      filter_on_type_step(page: cases_search_page,
                          types: ['foi_ir_compliance', 'foi_ir_timeliness'],
                          expected_cases: [
                            @setup.std_unassigned_irc,
                            @setup.std_unassigned_irt,
                            @setup.std_closed_irc,
                            @setup.std_closed_irt
                          ])

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
      search_for(search_phrase: 'prison guards', num_expected_results: 9)
      filter_on_type_step(page: cases_search_page,
                          types: ['foi_standard'],
                          sensitivity: ['trigger'],
                          expected_cases: [
                            @setup.trig_responded_foi,
                            @setup.trig_closed_foi,
                          ])

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

    scenario 'selecting both sensitivies then going back and unchecking one of them', js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 9)
      filter_on_type_step(page: cases_search_page,
                          sensitivity: ['non_trigger', 'trigger'],
                          expected_cases: [
                            @setup.std_draft_foi,
                            @setup.std_closed_foi,
                            @setup.trig_responded_foi,
                            @setup.trig_closed_foi,
                            @setup.std_unassigned_irc,
                            @setup.std_unassigned_irt,
                            @setup.std_closed_irc,
                            @setup.std_closed_irt,
                            @setup.sar_noff_draft,
                          ])

      expect(cases_search_page.filter_crumb_for('Non-trigger + 1 more'))
        .to be_present

      # Now uncheck non-trigger
      cases_search_page.remove_filter_on('type', 'non_trigger')
      expect(cases_search_page.case_numbers).to match_array expected_case_numbers(
                                                              :trig_responded_foi,
                                                              :trig_closed_foi
                                                            )


    end

    scenario 'filter by non-offender SAR', js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 9)

      filter_on_type_step(page: cases_search_page,
                          types: ['sar_non_offender'],
                          expected_cases: [@setup.sar_noff_draft])
    end

    scenario 'user without sar permissions is filtering', js: true do
      foi             = find_or_create(:foi_correspondence_type)
      responding_team = create(:business_unit, correspondence_types: [foi])
      user            = create(:user, responding_teams: [responding_team])

      login_step user: user
      cases_search_page.open_filter('type')
      expect(cases_search_page.type_filter_panel).to have_no_sar_non_offender_checkbox
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
        search_for(search_phrase: 'prison guards', num_expected_results: 12)
        cases_search_page.filter_on_exemptions(common: %w{ s40 } )
        expect(cases_search_page.case_numbers).to match_trimmed_array [ @ex2.number, @ex4.number ]

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
        search_for(search_phrase: 'prison guards', num_expected_results: 12)
        cases_search_page.filter_on_exemptions(common: %w{ s21 s22 } )
        expect(cases_search_page.case_numbers).to match_trimmed_array [ @ex1.number ]

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

  context 'all filters set' do
    before do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 9)

      cases_search_page.filter_on('status', 'open')
      cases_search_page.filter_on('type', 'foi_standard', 'trigger')

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
      expect(SearchQuery.count).to eq 7

      cases_search_page.filter_crumb_for(@from_to_date).click

      expect(SearchQuery.count).to eq 7
      expect(cases_search_page.filter_crumb_for('Open'                )).to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).not_to be_present

      cases_search_page.filter_crumb_for('Main responding_team').click

      expect(SearchQuery.count).to eq 7
      expect(cases_search_page.filter_crumb_for('Open'                )).to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).not_to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).not_to be_present

      cases_search_page.filter_crumb_for(@s40_exemption).click

      expect(SearchQuery.count).to eq 7
      expect(cases_search_page.filter_crumb_for('Open'                )).to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).not_to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).not_to be_present

      cases_search_page.filter_crumb_for('Trigger').click

      expect(SearchQuery.count).to eq 8
      expect(cases_search_page.filter_crumb_for('Open'                )).to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).not_to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).not_to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).not_to be_present

      cases_search_page.filter_crumb_for('FOI - Standard').click

      expect(SearchQuery.count).to eq 8
      expect(cases_search_page.filter_crumb_for('Open'                )).to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).not_to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption        )).not_to be_present
      expect(cases_search_page.filter_crumb_for('Main responding_team')).not_to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date         )).not_to be_present

      cases_search_page.filter_on('type', 'foi_standard', 'trigger')
      cases_search_page.filter_crumb_for('Open').click

      expect(SearchQuery.count).to eq 9
      expect(cases_search_page.filter_crumb_for('Open'                )).not_to be_present
      expect(cases_search_page.filter_crumb_for('FOI - Standard'      )).to be_present
      expect(cases_search_page.filter_crumb_for('Trigger'             )).to be_present
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

