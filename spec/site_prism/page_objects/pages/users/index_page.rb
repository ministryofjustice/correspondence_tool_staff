module PageObjects
  module Pages
    module Users
      class IndexPage < SitePrism::Page
        set_url '/users/'

        sections :users, '.user_row' do
          element :full_name, 'td[aria-label="Full name"]'
          element :email, 'td[aria-label="Email"]'
        end
      end
    end
  end
end
