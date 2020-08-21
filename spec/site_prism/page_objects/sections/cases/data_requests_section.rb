module PageObjects
  module Sections
    module Cases
      class DataRequestsSection < SitePrism::Section

        element :section_heading, '.data-requests__title'
        element :heading, 'thead tr'
        element :none, '.data-requests__none'

        sections :rows, 'tbody tr' do
          element :location, 'td:nth-child(1)'
          element :request_type, 'td:nth-child(2)'
          element :date_from, 'td:nth-child(3)'
          element :date_from_time, 'td:nth-child(3) time'
          # element :date_to, 'td:nth-child(4)'
          # element :date_to_time, 'td:nth-child(4) time'
          element :pages, 'td:nth-child(4)'
          element :status, 'td:nth-child(5)'
          element :action, '.data-requests__action'
          element :total_label, 'td:nth-child(1)'
          element :total_value, 'td:nth-child(2)'
        end
      end
    end
  end
end
