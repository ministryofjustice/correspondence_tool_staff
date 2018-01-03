require "rails_helper"

describe Case::SARDecorator do
  it 'instantiates the correct decorator' do
    expect(Case::SAR.new.decorate).to be_instance_of Case::SARDecorator
  end
end
