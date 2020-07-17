require "rails_helper"

describe Case::SAR::OffenderDecorator do
  let(:offender_sar_case) {create(:offender_sar_case).decorate }

  it 'instantiates the correct decorator' do
    expect(Case::SAR::Offender.new.decorate).to be_instance_of Case::SAR::OffenderDecorator
  end

  describe "#steps" do
    it "returns the list of steps" do
      expect(offender_sar_case.steps).to eq ["subject-details", "requester-details", "recipient-details", "requested-info", "request-details", "date-received"]
    end
  end

  describe "#current_step" do
    it "returns the first step by default" do
      expect(offender_sar_case.current_step).to eq "subject-details"
    end
  end

  describe "#next_step" do
    it "causes #current_step to return the next step" do
      offender_sar_case.next_step

      expect(offender_sar_case.current_step).to eq "requester-details"
    end
  end

  describe "#get_step_partial" do
    it "returns the first step as default filename" do
      expect(offender_sar_case.get_step_partial).to eq "subject_details_step"
    end

    it "returns each subsequent step as a partial filename" do
      expect(offender_sar_case.get_step_partial).to eq "subject_details_step"
      offender_sar_case.next_step
      expect(offender_sar_case.get_step_partial).to eq "requester_details_step"
      offender_sar_case.next_step
      expect(offender_sar_case.get_step_partial).to eq "recipient_details_step"
      offender_sar_case.next_step
      expect(offender_sar_case.get_step_partial).to eq "requested_info_step"
      offender_sar_case.next_step
      expect(offender_sar_case.get_step_partial).to eq "request_details_step"
      offender_sar_case.next_step
      expect(offender_sar_case.get_step_partial).to eq "date_received_step"
    end
  end

  describe "#valid_attributes?" do
    context "when params is empty" do
      params = ActionController::Parameters.new({}).permit!

      it "returns false" do
        expect(offender_sar_case.valid_attributes?(params)).to be false
      end
    end

    context "when params is nil" do
      let(:params) { nil }

      it "returns false" do
        expect(offender_sar_case.valid_attributes?(params)).to be false
      end
    end

    context "when params is set and not valid" do
      let(:params) { ActionController::Parameters.new(
        offender_sar_case: { name: "", email: "notanemail" }
      ).require(:offender_sar_case).permit(:name, :email)}

      context "and the form model has the values merged" do
        it "returns false" do
          expect(offender_sar_case.valid_attributes?(params)).to be false
        end
      end

      context "and the form model does not have the values merged" do
        it "returns false" do
          expect(offender_sar_case.valid_attributes?(params)).to be false
        end
      end
    end
  end

end
