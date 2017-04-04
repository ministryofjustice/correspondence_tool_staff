module PageObjects
  module Pages
    module Cases
      class AssignPage < SitePrism::Page
        set_url '/cases/{id}'
      end
    end
  end
end
