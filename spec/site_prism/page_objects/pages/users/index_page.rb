module PageObjects
  module Pages
    module Users
      class IndexPage < SitePrism::Page
        set_url "/users/"

        element :active_users, ".search-results-summary"

        sections :users, "tbody tr" do
          element :full_name, 'td[aria-label="Name"]'
          element :email, 'td[aria-label="Email"]'
        end
      end
    end
  end
end
