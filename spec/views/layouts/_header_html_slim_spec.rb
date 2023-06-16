require "rails_helper"

describe "layouts/_header.html.slim" do
  it "displays just a heading" do
    view.instance_variable_get("@view_flow").set(:heading, "My heading")

    render

    header_partial_page.load(rendered)

    @partial = header_partial_page.page_heading

    expect(@partial).to have_heading

    expect(@partial.heading.text).to eq "My heading"

    expect(@partial).to have_no_sub_heading
  end

  it "displays a heading and sub-heading" do
    view.instance_variable_get("@view_flow").set(:heading, "My heading")

    view.instance_variable_get("@view_flow").set(:sub_heading, "My sub-heading")

    render

    header_partial_page.load(rendered)

    @partial = header_partial_page.page_heading

    expect(@partial).to have_heading

    expect(@partial.heading.text).to eq "My heading"

    expect(@partial).to have_sub_heading

    expect(@partial.sub_heading.text).to eq "My sub-heading "
  end
end
