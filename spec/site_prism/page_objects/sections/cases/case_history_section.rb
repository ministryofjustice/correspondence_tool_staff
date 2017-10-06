module PageObjects
  module Sections
    module Cases
      class CaseHistorySection < SitePrism::Section
        element :section_heading, 'h2.request--heading'

        element :heading, 'thead tr'
        elements :entries, 'tbody tr'

        sections :rows, 'tbody tr' do
          element :action_date, 'td:nth-child(1)'
          element :user, 'td:nth-child(2)'
          element :team, 'td:nth-child(3)'
          element :details, 'td:nth-child(4)'
        end
      end
    end
  end
end
