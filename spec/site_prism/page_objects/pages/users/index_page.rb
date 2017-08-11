module PageObjects
  module Pages
    module Users
      class IndexPage < SitePrism::Page
        set_url '/users/'

        sections :users, 'tbody tr' do
          element :full_name, 'td[aria-label="Name"]'
          element :email, 'td[aria-label="Email"]'
        end
      end
    end
  end
end
