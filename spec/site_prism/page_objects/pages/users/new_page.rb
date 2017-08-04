module PageObjects
  module Pages
    module Users
      class NewPage < SitePrism::Page
        set_url '/users/new'

        element :team_id, '#team_id', visible: false
        element :full_name, '#full_name'
        element :email, '#email'
      end
    end
  end
end
