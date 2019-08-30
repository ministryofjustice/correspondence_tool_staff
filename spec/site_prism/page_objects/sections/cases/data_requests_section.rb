module PageObjects
  module Sections
    module Cases
      class DataRequestsSection < SitePrism::Section

        element :section_heading, '.data-requests__title'
        element :heading, 'thead tr'
        element :none, '.data-requests__none'

        sections :rows, 'tbody tr' do
          element :location, 'td:nth-child(1)'
          element :data, 'td:nth-child(2)'
          element :date_requested, 'td:nth-child(3)'
          element :pages, 'td:nth-child(4)'
          element :date_received, 'td:nth-child(5)'
          element :action, '.data-requests__action'
        end

      end
    end
  end
end

