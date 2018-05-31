###################################
#
# Stats - Downloading stats & custom reports
#
###################################

# Manager/responder signs in
# Views "Statistics" and displays stats page
# Clicks on R003 report
#   - expect report to download
# Clicks on R004 report
#   - expect report to download
# Clicks on R005 report
#   - expect report to download
# Clicks on "Create custom report" button
# "Create custom report page loads up"
# select a random report
# select a data range
# clicks export
# get flash click link to downloads
# downloads and redirects to custom page

require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
require File.join(Rails.root, 'db', 'seeders', 'report_type_seeder')


# ReportTypeSeeder.new.seed!


feature "Downloading stats(csv) from the system" do
  given(:manager)  { create :manager }
  given(:responder){ create :responder }
  given(:kase)     { create :case }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!(verbose: false)
    ReportTypeSeeder.new.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
    ReportType.destroy_all
  end

  background do
    manager
    responder
    kase
  end
  context 'as a manager' do
    scenario "standard reports" do
      # Manager creates & assigns to kilo
      login_as_manager
      views_stats_home_page
      download_r002_report
      download_r003_report
      download_r004_report
      download_r005_report
    end

    scenario "custom reports" do
      # Manager creates & assigns to kilo
      login_as_manager
      views_stats_home_page
      view_custom_report_creation_page
      create_custom_r003_report
      download_custom_r003_report
      create_custom_r004_report
      download_custom_r004_report

    end
  end
  context 'as a responder' do
    scenario "standard reports" do
      # Manager creates & assigns to kilo
      login_as_responder
      views_stats_home_page
      download_r002_report
      download_r003_report
      download_r004_report
      download_r005_report
    end

    scenario "custom reports" do
      # Manager creates & assigns to kilo
      login_as_responder
      views_stats_home_page
      view_custom_report_creation_page
      create_custom_r003_report
      download_custom_r003_report
      create_custom_r004_report
      download_custom_r004_report

    end
  end



  private

  def login_as_manager
    login_as manager

    open_cases_page.load
  end

  def login_as_responder
    login_as responder

    open_cases_page.load
  end

  def views_stats_home_page
    open_cases_page.primary_navigation.stats.click
    expect(stats_index_page).to be_displayed
  end

  def download_r002_report
    stats_index_page.reports.first.action_link.click
    expect(page.response_headers['Content-Disposition'])
        .to match(/filename="r002_appeals_performance_report\.csv"/)
    stats_index_page.load
  end

  def download_r003_report
    stats_index_page.reports.second.action_link.click
    expect(page.response_headers['Content-Disposition'])
        .to match(/filename="r003_business_unit_performance_report\.csv"/)
    stats_index_page.load
  end

  def download_r004_report
    stats_index_page.reports.fourth.action_link.click
    expect(page.response_headers['Content-Disposition'])
        .to match(/filename="r004_cabinet_office_report.csv"/)
    stats_index_page.load
  end

  def download_r005_report
    stats_index_page.reports.third.action_link.click
    expect(page.response_headers['Content-Disposition'])
        .to match(/filename="r005_monthly_performance_report.csv"/)
    stats_index_page.load
  end


  def view_custom_report_creation_page
    stats_index_page.custom_reports.click
    expect(stats_custom_page).to be_displayed
  end

  def create_custom_r003_report
    r003 = ReportType.where(abbr:'R003').first
    stats_custom_page.fill_in_form(r003.id, Date.yesterday, Date.today)
    stats_custom_page.submit_button.click

    expect(stats_custom_page.success_message).to have_download_link
  end

  def download_custom_r003_report
    stats_custom_page.success_message.download_link.click
    expect(page.response_headers['Content-Disposition'])
        .to match(/filename="r003_business_unit_performance_report\.csv"/)

    stats_custom_page.load
  end

  def create_custom_r004_report
    r005 = ReportType.where(abbr:'R005').first
    stats_custom_page.fill_in_form(r005.id, Date.yesterday, Date.today)
    stats_custom_page.submit_button.click

    expect(stats_custom_page.success_message).to have_download_link
  end

  def download_custom_r004_report
    stats_custom_page.success_message.download_link.click
    expect(page.response_headers['Content-Disposition'])
        .to match(/filename="r005_monthly_performance_report\.csv"/)

    stats_custom_page.load
  end
end
