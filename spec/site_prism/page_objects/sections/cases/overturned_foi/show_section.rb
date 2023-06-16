require "page_objects/sections/cases/overturned_foi/case_details_section"
require "page_objects/sections/cases/case_request_section"
require "page_objects/sections/cases/ico/ico_decision_section"
require "page_objects/sections/cases/linked_cases_section"

module PageObjects
  module Sections
    module Cases
      module OverturnedFOI
        class ShowSection < SitePrism::Section
          section :original_cases,
                  PageObjects::Sections::Cases::LinkedCasesSection,
                  ".original-linked-case"

          section :related_cases,
                  PageObjects::Sections::Cases::LinkedCasesSection,
                  ".related-linked-cases"

          section :ico_decision_section,
                  PageObjects::Sections::Cases::ICO::ICODecisionSection,
                  ".ico-decision-section"

          section :case_details,
                  PageObjects::Sections::Cases::OverturnedFOI::CaseDetailsSection,
                  ".case-details"

          section :request,
                  PageObjects::Sections::Cases::CaseRequestSection,
                  ".request"

          section :original_case_details, ".original-case-details" do
            element :link_to_case, "a"
          end
        end
      end
    end
  end
end
