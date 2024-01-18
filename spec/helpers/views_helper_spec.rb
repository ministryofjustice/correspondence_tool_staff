require "rails_helper"

describe "Creating an offender sar case"
  context "when user is adding a rejected offender sar case"
    it "should set H1 title" do
      page_title("Create a rejected offender sar")
      render "layouts/header"
      rendered.should have_selector('title:contains("Create a rejected offender sar")')
    end
  end
end
