require "rails_helper"

describe Case::ICO::BaseDecorator do
  it 'instantiates the correct decorator' do
    expect(Case::ICO::Base.new.decorate).to be_instance_of Case::ICO::BaseDecorator
  end
end
