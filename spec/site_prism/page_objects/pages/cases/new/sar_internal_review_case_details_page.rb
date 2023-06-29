module PageObjects
  module Pages
    module Cases
      module New
        class SarInternalReviewCaseDetailsPage < PageObjects::Pages::Base
          include SitePrism::Support::DropInDropzone

          set_url "/cases/sar_internal_review_internal_review/case-details"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :compliance_subtype, "#sar_internal_review_sar_ir_subtype_compliance", visible: false

          element :third_party_true, "#sar_internal_review_third_party_true", visible: false

          element :third_party, :xpath,
                  "//fieldset[contains(.,\"being requested on someone else's behalf\")]"

          element :requestor_full_name, "#sar_internal_review_name", visible: false
          element :third_party_relationship, "#sar_internal_review_third_party_relationship"

          element :date_received_day, "#sar_internal_review_received_date_dd"
          element :date_received_month, "#sar_internal_review_received_date_mm"
          element :date_received_year, "#sar_internal_review_received_date_yyyy"

          element :case_summary, "#sar_internal_review_subject"
          element :full_case_details, "#sar_internal_review_message"
          element :dropzone_container, ".dropzone"

          element :date_today_link, "#sar_internal_review_received_date > fieldset > div > a"

          # only shows up when using drop_in_dropzone
          element :uploaded_request_file_input, "#uploadedRequestFileInput"

          element :reply_method, :xpath,
                  '//fieldset[contains(.,"Where the information should be sent")]'
          element :email, "#sar_internal_review_email"

          element :send_by_post, "#sar_internal_review_reply_method_send_by_post", visible: false

          element :postal_address, "#sar_internal_review_postal_address", visible: false

          element :submit_button, ".button"

          def set_received_date(received_date)
            date_received_day.set(received_date.day)
            date_received_month.set(received_date.month)
            date_received_year.set(received_date.year)
          end

          def fill_in_requestor_name(name)
            requestor_full_name.set(name)
          end

          def fill_in_third_party_relationship(relationship)
            third_party_relationship.set(relationship)
          end

          def fill_in_full_case_details(details)
            full_case_details.set(details)
          end

          def fill_in_postal_address(address)
            postal_address.set(address)
          end

          def drop_in_dropzone(file_path)
            super file_path:,
                  input_name: dropzone_container["data-file-input-name"],
                  container_selector: ".dropzone"
          end
        end
      end
    end
  end
end
