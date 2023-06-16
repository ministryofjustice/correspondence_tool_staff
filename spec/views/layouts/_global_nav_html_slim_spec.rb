require "rails_helper"

describe "layouts/_global_nav.html.slim" do
  let(:single_team_user)      { double User, teams: %w[team] }
  let(:multi_team_user)       { double User, teams: %w[team1 team2] }

  def render_page
    nav_man = instance_double(GlobalNavManager)
    allow(nav_man).to receive(:each)
                        .and_yield(instance_double(GlobalNavManager::Page,
                                                   name: "nav1",
                                                   fullpath: "/nav1"))
                        .and_yield(instance_double(GlobalNavManager::Page,
                                                   name: "nav2",
                                                   fullpath: "/nav2"))
    assign(:global_nav_manager, nav_man)
    render
    global_nav_partial_page.load(rendered)
    @partial = global_nav_partial_page
  end

  it "displays a link for every entry in the Nav bar" do
    allow(view).to receive(:current_user).and_return(multi_team_user)
    render_page

    expect(@partial.global_nav.all_links.size).to eq 2

    expect(@partial.global_nav.all_links.first[:href]).to eq "/nav1"
    expect(@partial.global_nav.all_links.first.text).to eq "Nav1"

    expect(@partial.global_nav.all_links.last[:href]).to eq "/nav2"
    expect(@partial.global_nav.all_links.last.text).to eq "Nav2"
  end

  describe "active link" do
    it "marks link as active if it is the current page" do
      allow(view).to receive(:current_page?).and_return(false)
      allow(view).to receive(:current_page?).with("/nav1").and_return(true)
      allow(view).to receive(:current_user).and_return(multi_team_user)
      render_page
      expect(@partial.global_nav.active_link.text).to eq "Nav1"
    end

    it "does not mark as active links that are not the current page" do
      allow(view).to receive(:current_page?).and_return(false)
      allow(view).to receive(:current_user).and_return(single_team_user)
      render_page
      expect(@partial.global_nav).to have_no_active_link
    end
  end
end
