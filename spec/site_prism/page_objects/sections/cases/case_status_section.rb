module PageObjects
  module Sections
    module Cases
      class CaseStatusSection < SitePrism::Section

        section :details , '.case-status--intime' do
          element :copy_label , '.status .case-status__heading'
          element :copy ,
                  '.status .case-status__data---large'
          element :who_its_with_label,
                  '.who_its_with .case-status__heading'
          element :who_its_with,
                  '.who_its_with .case-status__data'
        end

        section :deadlines , '.case-status__deadline' do
          element :draft_label , '.draft .case-status__heading'
          element :draft , '.draft .case-status__data'
          element :final_label, '.external .case-status__heading'
          element :final, '.external .case-status__data'
        end
      end
    end
  end
end
