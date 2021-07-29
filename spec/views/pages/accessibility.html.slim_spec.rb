require 'rails_helper'

RSpec.describe "pages/accessibility.html.slim", type: :view do
  it 'displays the creators email address' do
    render

    expect(rendered).to have_text('Accessibility statement')
    expect(rendered).to have_text("It was last updated")
  end
end
