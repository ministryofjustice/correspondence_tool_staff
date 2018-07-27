require "rails_helper"

describe Case::ICO::SARDecorator do
  let(:ico_sar_case) { build :ico_sar_case }

  it 'instantiates the correct decorator' do
    expect(Case::ICO::SAR.new.decorate).to be_instance_of Case::ICO::SARDecorator
  end

  describe '#type_printer' do
    it 'pretty prints Case' do
      expect(ico_sar_case.decorate.pretty_type).to eq 'ICO appeal for SAR case'
    end
  end
end
