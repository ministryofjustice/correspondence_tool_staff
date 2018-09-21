require "rails_helper"

describe 'cases/overturned_shared/_new.html.slim' do
  let(:bmt_manager) { create(:disclosure_bmt_user) }
  let(:ico_appeal)  { create(:closed_ico_sar_case) }

  def render_partial
    render
    overturned_foi_form_section(rendered)
  end

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  before(:each) { login_as bmt_manager }

  let(:overturned_foi) { find_or_create(:overturned_foi_correspondence_type) }

  it 'renders a form for overturned_foi' do
    assign(:case, build(:overturned_ico_foi).decorate)
    assign(:correspondence_type, overturned_foi)
    assign(:correspondence_type_key, 'overturned_foi')

    partial = render_partial

    expect(partial).to have_date_received_day
  end
end
