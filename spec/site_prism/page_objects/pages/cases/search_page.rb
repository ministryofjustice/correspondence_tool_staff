module PageObjects
  module Pages
    module Cases
      class SearchPage < SitePrism::Page
        set_url '/cases/search'

        sections :notices, '.notice-summary' do
          element :heading, '.notice-summary-heading'
        end

        element :search_query, 'input[type="search"]'
        element :search_button, 'input.button'

        element :search_results_count, '.search-results-summary'

        sections :case_list, '.report tbody tr' do
          element :number, 'td[aria-label="Case number"]'
          element :request_detail, 'td[aria-label="Request detail"]'
          element :draft_deadline, 'td[aria-label="Draft deadline"]'
          element :external_deadline, 'td[aria-label="Final deadline"]'
          element :status, 'td[aria-label="Status"]'
          element :who_its_with, 'td[aria-label="With"]'
        end

        element :found_no_results_copy, '.search-no-results'
      end
    end
  end
end
