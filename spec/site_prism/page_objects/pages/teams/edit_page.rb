require "page_objects/pages/teams/new_page"

module PageObjects
  module Pages
    module Teams
      class EditPage < PageObjects::Pages::Teams::NewPage
        # Inherits from the new page
        set_url "/teams/{id}/edit"
      end
    end
  end
end
