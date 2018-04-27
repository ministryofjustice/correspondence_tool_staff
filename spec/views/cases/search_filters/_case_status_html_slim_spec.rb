require "rails_helper"

describe 'cases/search_filters/_case_status.html.slim', type: :view do
  let(:search_query) { create :search_query }
  let(:partial) do
    render partial: 'cases/search_filters/case_status.html.slim',
           locals: { :@query => search_query }
    case_status_filter_panel_section(rendered)
  end

  subject { partial }

  it { should have_hidden_checkbox }
  it { should have_open_checkbox }
  it { should have_closed_checkbox }
  it { should have_apply_filter_button }
  xit { should have_cancel_link }
end
