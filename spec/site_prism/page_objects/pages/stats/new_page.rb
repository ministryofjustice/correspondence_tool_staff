module PageObjects
  module Pages
    module Stats
      class NewPage < PageObjects::Pages::Base
        set_url "/stats/new"

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        section :success_message, ".notice-summary" do
          element :download_link, "a"
        end

        section :correspondence_type, "#js-correspondence-types" do
          elements :correspondence_types, "label"
        end

        element :foi_report, "#report_correspondence_type_foi"
        element :sar_report, "#report_correspondence_type_sar"
        element :closed_cases_report, "#report_correspondence_type_closed_cases"

        section :options_foi, ".report-type-options--foi" do
          elements :reports, "input"
        end

        section :options_sar, ".report-type-options--sar" do
          elements :reports, "input"
        end

        section :options_closed_cases, ".report-type-options--closed-cases" do
          elements :reports, "input", visible: false
        end

        section :period_start, ".period-start" do
          element :day, "#report_period_start_dd"
          element :month, "#report_period_start_mm"
          element :year, "#report_period_start_yyyy"
        end

        section :period_end, ".period-end" do
          element :day, "#report_period_end_dd"
          element :month, "#report_period_end_mm"
          element :year, "#report_period_end_yyyy"
        end

        element :submit_button, ".button"

        def fill_in_period_start(date)
          period_start.day.set(date.day)
          period_start.month.set(date.month)
          period_start.year.set(date.year)
        end

        def fill_in_period_end(date)
          period_end.day.set(date.day)
          period_end.month.set(date.month)
          period_end.year.set(date.year)
        end

        def choose_type_of_correspondence(correspondence_type)
          make_radio_button_choice("report_correspondence_type_#{correspondence_type}")
        end

        def choose_type_of_report(report_id)
          make_radio_button_choice("report_report_type_id_#{report_id}")
        end

        def fill_in_form(correspondence_type = "foi", report_id, period_start_date, period_end_date)
          choose_type_of_correspondence(correspondence_type.downcase)
          choose_type_of_report(report_id)
          fill_in_period_start(period_start_date)
          fill_in_period_end(period_end_date)
        end
      end
    end
  end
end
