require "rails_helper"

describe CorrespondenceTypeDecorator do
  let(:foi)                     { create(:foi_correspondence_type) }
  let(:ico)                     { create(:ico_correspondence_type) }
  let(:sar)                     { create(:sar_correspondence_type) }
  let(:offender_sar)            { create(:offender_sar_correspondence_type) }
  let(:offender_sar_complaint)  { create(:offender_sar_complaint_correspondence_type) }

  it "instantiates the correct decorator" do
    expect(CorrespondenceType.new.decorate).to be_instance_of described_class
  end

  describe "#type_printer" do
    it "pretty name" do
      validate_type_pretty_name(foi, "foi")
      validate_type_pretty_name(ico, "ico")
      validate_type_pretty_name(sar, "sar")
      validate_type_pretty_name(offender_sar, "offender_sar")
      validate_type_pretty_name(offender_sar_complaint, "offender_sar_complaint")
    end
  end

private

  def validate_type_pretty_name(correspondence_type, type_name)
    expect(correspondence_type.decorate.pretty_name).to have_content I18n.t("helpers.label.correspondence_types.#{type_name}")
    expect(correspondence_type.decorate.pretty_name).to have_content correspondence_type.name
  end
end
