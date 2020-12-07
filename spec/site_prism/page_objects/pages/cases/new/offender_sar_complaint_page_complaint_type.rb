module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARComplaintPageComplaintType < PageObjects::Pages::Base

          set_url '/cases/offender_sar_complaints/complaint-type'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :submit_button, '.button'

          def fill_in_case_details(params={})
            kase = FactoryBot.build :offender_sar_complaint, params

            fill_in_complaint_type(kase)
            fill_in_complaint_subtype(kase)
            fill_in_priority(kase)
          end

          def fill_in_complaint_type(kase)
            if kase.standard?
              choose('offender_sar_complaint_complaint_type_standard', visible: false)
            elsif kase.ico?
              choose('offender_sar_complaint_complaint_type_ico', visible: false)
            elsif kase.litigation?
              choose('offender_sar_complaint_complaint_type_litigation', visible: false)
            end
          end

          def fill_in_complaint_subtype(kase)
            if kase.missing_data?
              choose('offender_sar_complaint_complaint_subtype_missing_data', visible: false)
            elsif kase.inaccurate_data?
              choose('offender_sar_complaint_complaint_subtype_inaccurate_data', visible: false)
            elsif kase.redacted_data?
              choose('offender_sar_complaint_complaint_subtype_redacted_data', visible: false)
            elsif kase.timeliness?
              choose('offender_sar_complaint_complaint_subtype_timeliness', visible: false)
            end
          end

          def fill_in_priority(kase)
            if kase.normal_priority?
              choose('offender_sar_complaint_priority_normal', visible: false)
            elsif kase.high_priority?
              choose('offender_sar_complaint_priority_standard', visible: false)
            end
          end

        end
      end
    end
  end
end
