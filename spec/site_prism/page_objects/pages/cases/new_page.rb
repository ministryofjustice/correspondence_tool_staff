module PageObjects
  module Pages
    module Cases
      class NewPage < PageObjects::Pages::Base
        set_url "/cases/new"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        elements :create_links, "#create-correspondences > li > a"

        element :submit_button, ".button"

        def create_link_for_correspondence(correspondence_type)
          create_links.find { |link| link.text.downcase.match(correspondence_type.downcase) }
        end

        def fill_in_case_type(choice)
          make_radio_button_choice("foi_type_#{choice}")
          click_button "Continue"
        end
      end
    end
  end
end
