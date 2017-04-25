require 'rails_helper'

describe 'layouts/_global_nav.html.slim' do

  def render_page
    user = double(User)
    assign(:global_nav_manager, GlobalNavManager.new(user))
    render
    global_nav_partial_page.load(rendered)
    @partial = global_nav_partial_page
  end


  it 'displays a link for every entry in the Nav bar' do
    render_page

    expect(@partial.global_nav.all_links.size).to eq 2

    expect(@partial.global_nav.all_links.first[:href]).to eq cases_path
    expect(@partial.global_nav.all_links.first.text).to eq 'Open cases'

    expect(@partial.global_nav.all_links.last[:href]).to eq closed_cases_path
    expect(@partial.global_nav.all_links.last.text).to eq 'Closed cases'
  end

  describe 'active link' do
    context 'root path' do
      it 'marks cases as active' do
        allow(view).to receive(:current_page?).and_return(false)
        allow(view).to receive(:current_page?).with('/').and_return(true)
        render_page
        expect(@partial.global_nav.active_link.text).to eq 'Open cases'
      end
    end

    context 'cases path' do
      it 'marks cases as active' do
        allow(view).to receive(:current_page?).and_return(false)
        allow(view).to receive(:current_page?).with('/cases').and_return(true)
        render_page
        expect(@partial.global_nav.active_link.text).to eq 'Open cases'
      end
    end

    context 'closed cases path' do
      it 'marks closecd cases as active' do
        allow(view).to receive(:current_page?).and_return(false)
        allow(view).to receive(:current_page?).with('/cases/closed').and_return(true)
        render_page
        expect(@partial.global_nav.active_link.text).to eq 'Closed cases'
      end
    end

    context 'new case path' do
      it 'has no active link' do
        allow(view).to receive(:current_page?).and_return(false)
        allow(view).to receive(:current_page?).with('/cases/new').and_return(false)
        render_page
        expect(@partial.global_nav).to have_no_active_link
      end
    end
  end
end

