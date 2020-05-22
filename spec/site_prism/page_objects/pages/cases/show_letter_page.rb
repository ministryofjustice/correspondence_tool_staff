module PageObjects
  module Pages
    module Cases
      class ShowLetterPage < SitePrism::Page
        set_url '/cases/{case_id}/letters/{type}'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :letter_from_section, 'letter--from-section'

        element :recipient_address, '.recipient-address'
        element :save_word_document_button, '.save-word-document'
      end
    end
  end
end

