require 'page_objects/sections/cases/ico/case_details_section'

module PageObjects
  module Sections
    module Cases
      module ICO
        class ShowSection < SitePrism::Section
          section :original_cases,
                  PageObjects::Sections::Cases::LinkedCasesSection,
                  '.original-linked-case'

          section :related_cases,
                  PageObjects::Sections::Cases::LinkedCasesSection,
                  '.related-linked-cases'

          section :case_details,
                  PageObjects::Sections::Cases::ICO::CaseDetailsSection,
                  '.case-details'

          section :request,
                  PageObjects::Sections::Cases::CaseRequestSection,
                  '.request'
        end
      end
    end
  end
end

