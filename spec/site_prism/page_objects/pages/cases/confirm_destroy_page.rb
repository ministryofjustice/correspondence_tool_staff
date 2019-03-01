module PageObjects
  module Pages
    module Cases
      class ConfirmDestroyPage < SitePrism::Page
        set_url '/cases/{id}/confirm_destroy'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :delete_copy, '.delete-copy .delete-message'

        element :warning, '.delete-copy .notice'

        element :reason_for_deletion, '#case_reason_for_deletion'
        element :reason_for_deletion_error, '#error_message_case_reason_for_deletion'

        element :confirm_button, '.button'
        element :cancel, 'a.acts-like-button.button-left-spacing'

        # Confirm button is a form submit, so the displayed text is the 'value' property
        def confirm_button_text
          confirm_button.value
        end

        def fill_in_delete_reason
          # reason_for_deletion.set 'I want this case deleted'
          fill_in('Reason for deletion', with: 'I want this case deleted')
        end
      end
    end
  end
end
