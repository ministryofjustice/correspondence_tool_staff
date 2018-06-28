require "rails_helper"

describe CasesController, type: :controller do
  let(:manager)      { create :disclosure_bmt_user }
  let(:controller)   { described_class.new }
  let!(:sar)         { find_or_create :sar_correspondence_type }
  let!(:ico)         { find_or_create :ico_correspondence_type }
  let(:sars_feature) { instance_double(FeatureSet::EnabledFeature,
                                       enabled?: true) }
  let(:ico_feature)  { instance_double(FeatureSet::EnabledFeature,
                                       enabled?: true) }


  before do
    allow(controller).to receive(:current_user).and_return(manager)
    allow(FeatureSet).to receive(:sars).and_return(sars_feature)
    allow(FeatureSet).to receive(:ico).and_return(ico_feature)
  end

  it 'does permit SAR cases if feature is enabled' do
    allow(sars_feature).to receive(:enabled?).and_return(true)
    types = controller.__send__(:permitted_correspondence_types)
    expect(types).to include sar
  end

  it 'does not permit SAR cases if feature is not enabled' do
    allow(sars_feature).to receive(:enabled?).and_return(false)
    types = controller.__send__(:permitted_correspondence_types)
    expect(types).not_to include sar
  end

  it 'does permit ICO cases if feature is enabled' do
    allow(ico_feature).to receive(:enabled?).and_return(true)
    types = controller.__send__(:permitted_correspondence_types)
    expect(types).to include ico
  end

  it 'does not permit ICO cases if feature is not enabled' do
    allow(ico_feature).to receive(:enabled?).and_return(false)
    types = controller.__send__(:permitted_correspondence_types)
    expect(types).not_to include ico
  end
end
