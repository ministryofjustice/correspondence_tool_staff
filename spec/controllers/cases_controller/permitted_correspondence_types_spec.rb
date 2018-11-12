require "rails_helper"

describe CasesController, type: :controller do
  let(:manager)      { find_or_create :disclosure_bmt_user }
  let(:controller)   { described_class.new }
  let!(:sar)         { find_or_create :sar_correspondence_type }
  let!(:ico)         { find_or_create :ico_correspondence_type }

  before do
    allow(controller).to receive(:current_user).and_return(manager)
  end

  it 'does permit SAR cases if feature is enabled' do
    enable_feature(:sars)
    types = controller.__send__(:permitted_correspondence_types)
    expect(types).to include sar
  end

  it 'does not permit SAR cases if feature is not enabled' do
    disable_feature(:sars)
    types = controller.__send__(:permitted_correspondence_types)
    expect(types).not_to include sar
  end

  it 'does permit ICO cases if feature is enabled' do
    enable_feature(:sars)
    types = controller.__send__(:permitted_correspondence_types)
    expect(types).to include ico
  end

  it 'does not permit ICO cases if feature is not enabled' do
    disable_feature(:ico)
    types = controller.__send__(:permitted_correspondence_types)
    expect(types).not_to include ico
  end
end
