module PageObjects
  module Pages
    module Cases
      class ShowPage < SitePrism::Page
        set_url '/cases/{id}'

        section :user_card, PageObjects::Sections::UserCardSection, '.user-card'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        element :happy_action_notice, '.alert-green'
        element :escalation_notice, '.alert-orange'
        element :notice, '.notice-summary-heading'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :actions, '.button-holder' do
          element :upload_response, '#action--upload-response'
          element :mark_as_sent, '#action--mark-response-as-sent'
          element :close_case, '#action--close-case'
          element :clear_case, '#action--approve'
          element :request_amends, '#action--request-amends'
          element :upload_approve, '#action--upload-approve'
          element :upload_redraft, '#action--upload-redraft'
          element :reassign_user, '#action--reassign-case'
        end
        element :extend_for_pit_action, '#action--extend-for-pit'

        section :case_status,
                PageObjects::Sections::Cases::CaseStatusSection, '.case-status'

        section :link_case,
                PageObjects::Sections::Cases::LinkedCasesSection, '.case-linking'

        section :case_details,
                PageObjects::Sections::Cases::CaseDetailsSection, '.case-details'

        section :clearance_levels,
                PageObjects::Sections::Cases::ClearanceLevelsSection, '.clearance-details'

        section :request,
                PageObjects::Sections::Cases::CaseRequestSection, '.request'

        sections :case_attachments,
                PageObjects::Sections::Cases::CaseAttachmentSection,
                '.case-attachments-group'

        section :what_do_you_want_to_do,
                PageObjects::Sections::Cases::WhatDoYouWantToDoSection,
                '.what-do-you-want-to-do'

        sections :messages, '#messages-section .message' do
          element :body, '.message-body'
          element :audit, '.message-audit'
        end

        section :new_message, '.message-form' do
          element :input, 'textarea'
          element :add_button, '.button'
        end

        section :case_history,
                PageObjects::Sections::Cases::CaseHistorySection, '#case-history'

        def collection_for_case_attachment(file)
          case_attachments.each do |case_attachment|
            case_attachment.collection.each do |collection|
              return collection if collection.filename.text == file
            end
          end
          nil
        end

        def add_message_to_case(message)
          new_message.input.set message
          new_message.add_button.click
        end
      end

    end
  end
end
