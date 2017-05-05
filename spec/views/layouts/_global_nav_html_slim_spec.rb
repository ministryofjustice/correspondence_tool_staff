require 'rails_helper'

describe 'layouts/_global_nav.html.slim' do

  def render_page
    nav_man = instance_double(GlobalNavManager)
    allow(nav_man).to receive(:each)
                        .and_yield(double 'GlobalNavManagerEntry',
                                          text: 'nav1',
                                          urls: ['http://localhost/nav1'],
                                          url: 'http://localhost/nav1')
                        .and_yield(double 'GlobalNavManagerEntry',
                                          text: 'nav2',
                                          urls: ['http://localhost/nav2'],
                                          url: 'http://localhost/nav2')
    assign(:global_nav_manager, nav_man)
    render
    global_nav_partial_page.load(rendered)
    @partial = global_nav_partial_page
  end


  it 'displays a link for every entry in the Nav bar' do
    render_page

    expect(@partial.global_nav.all_links.size).to eq 2

    expect(@partial.global_nav.all_links.first[:href])
      .to eq 'http://localhost/nav1'
    expect(@partial.global_nav.all_links.first.text).to eq 'nav1'

    expect(@partial.global_nav.all_links.last[:href])
      .to eq 'http://localhost/nav2'
    expect(@partial.global_nav.all_links.last.text).to eq 'nav2'
  end

  describe 'active link' do
    it 'marks link as active if it is the current page' do
      allow(view).to receive(:current_page?).and_return(false)
      allow(view).to receive(:current_page?).with('http://localhost/nav1').and_return(true)
      render_page
      expect(@partial.global_nav.active_link.text).to eq 'nav1'
    end

    it 'does not mark as active links that are not the current page' do
      allow(view).to receive(:current_page?).and_return(false)
      render_page
      expect(@partial.global_nav).to have_no_active_link
    end
  end
end

