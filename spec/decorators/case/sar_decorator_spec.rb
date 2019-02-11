require "rails_helper"

describe Case::SARDecorator do
  let(:decorated_sar_case) { create(:sar_case,
                                     subject_type: "member_of_the_public")
                              .decorate }

  it 'instantiates the correct decorator' do
    expect(Case::SAR.new.decorate).to be_instance_of Case::SARDecorator
  end

  it 'formats the requester type' do
    expect(decorated_sar_case.subject_type_display).to eq 'Member of the public'
  end
end
