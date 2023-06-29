module PageObjects
  module Pages
    module Assignments
      class ShowRejectedPage < SitePrism::Page
        set_url "/cases/{case_id}/assignments/show_rejected"

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        element :new_rejection_notice, ".alert-green"
        element :already_rejected_notice, ".alert-orange"
        element :message_label, ".request--heading"
        element :message, ".request--message"
      end
    end
  end
end
