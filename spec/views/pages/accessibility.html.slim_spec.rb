require "rails_helper"

RSpec.describe "pages/accessibility.html.slim", type: :view do
  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  let(:manager) { create :manager }

  it "displays th last updated date" do
    render

    expect(rendered).to have_text("Accessibility statement")
    expect(rendered).to have_text("It was last updated")
  end

  it "shows the feedback form link for a logged in user" do
    login_as manager

    render

    expect(rendered).to have_text("Use the feedback form at the bottom of this website")
  end

  it "does not show the feedback form link for a non-logged in user" do
    expect(rendered).not_to have_text("Use the feedback form at the bottom of this website")
  end
end
