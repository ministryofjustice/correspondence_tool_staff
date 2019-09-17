module PageObjects
  module Pages
    module Cases
      class NewLetterPage < SitePrism::Page
        set_url '/cases/{case_id}/letters/{type}{/new}'

        section :primary_navigation,
          PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
          PageObjects::Sections::PageHeadingSection, '.page-heading'

        # section :letter_template_id, '.js-info-held-status' do
        #   element :held, 'input#foi_info_held_status_abbreviation_held', visible: false
        #   element :yes,  'input#foi_info_held_status_abbreviation_held', visible: false

        #   element :part_held,    'input#foi_info_held_status_abbreviation_part_held', visible: false
        #   element :held_in_part, 'input#foi_info_held_status_abbreviation_part_held', visible: false

        #   element :not_held, 'input#foi_info_held_status_abbreviation_not_held', visible: false
        #   element :no,       'input#foi_info_held_status_abbreviation_not_held', visible: false

        #   element :not_confirmed, 'input#foi_info_held_status_abbreviation_not_confirmed', visible: false
        #   element :other,         'input#foi_info_held_status_abbreviation_not_confirmed', visible: false
        # end

        element :submit_button, '.button'
      end
    end
  end
end

