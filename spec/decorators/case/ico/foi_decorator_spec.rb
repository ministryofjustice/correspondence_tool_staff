require "rails_helper"

describe Case::ICO::FOIDecorator do
  let(:ico_foi_case) { build :ico_foi_case }

  it 'instantiates the correct decorator' do
    expect(Case::ICO::FOI.new.decorate).to be_instance_of Case::ICO::FOIDecorator
  end

  describe '#type_printer' do
    it 'pretty prints Case' do
      expect(ico_foi_case.decorate.pretty_type).to eq 'ICO appeal for FOI case'
    end
  end
end
