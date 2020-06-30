require 'rails_helper'

RSpec.describe OffenderSARCaseForm, type: :model do
  let(:case_form) { OffenderSARCaseForm.new({}) }

  it 'can be created' do
    expect(case_form.case).to be_an_instance_of Case::SAR::Offender
  end

  context "when session contains some data" do
    subject { OffenderSARCaseForm.new(double("session", :[] => { "name" => "Bob Smith" })) }

    it "sets the case offender name from the session" do
      expect(subject.name).to eq "Bob Smith"
    end
  end

  describe "#assign_params" do
    let(:params) { { "name" => "Bob Smith" } }

    it "merges values from params" do
      case_form.assign_params(params)

      expect(case_form.name).to eq "Bob Smith"
    end
  end

  describe "#steps" do
    it "returns the list of steps" do
      expect(case_form.steps).to eq ["subject-details", "requester-details", "recipient-details", "requested-info", "request-details", "date-received"]
    end
  end

  describe "#current_step" do
    it "returns the first step by default" do
      expect(case_form.current_step).to eq "subject-details"
    end
  end

  describe "#next_step" do
    it "causes #current_step to return the next step" do
      case_form.next_step

      expect(case_form.current_step).to eq "requester-details"
    end
  end

  describe "#get_step_partial" do
    it "returns the first step as default filename" do
      expect(case_form.get_step_partial).to eq "subject_details_step"
    end

    it "returns each subsequent step as a partial filename" do
      expect(case_form.get_step_partial).to eq "subject_details_step"
      case_form.next_step
      expect(case_form.get_step_partial).to eq "requester_details_step"
      case_form.next_step
      expect(case_form.get_step_partial).to eq "recipient_details_step"
      case_form.next_step
      expect(case_form.get_step_partial).to eq "requested_info_step"
      case_form.next_step
      expect(case_form.get_step_partial).to eq "request_details_step"
      case_form.next_step
      expect(case_form.get_step_partial).to eq "date_received_step"
    end
  end

  describe "#valid_attributes?" do
    context "when params is empty" do
      params = ActionController::Parameters.new({}).permit!

      it "returns false" do
        expect(case_form.valid_attributes?(params)).to be false
      end
    end

    context "when params is nil" do
      let(:params) { nil }

      it "returns false" do
        expect(case_form.valid_attributes?(params)).to be false
      end
    end

    context "when params is set and valid" do
      let(:params) { ActionController::Parameters.new(
        case_form: { subject_type: "offender", date_of_birth: "2001-01-01", flag_as_high_profile: "no" }
      ).require(:case_form).permit(:subject_type, :date_of_birth, :flag_as_high_profile)}

      context "and the form model has the values merged" do
        it "returns true" do
          case_form.assign_params(params)

          expect(case_form.valid_attributes?(params)).to be true
        end
      end

      context "and the form model does not have the values merged" do
        it "returns false" do
          expect(case_form.valid_attributes?(params)).to be false
        end
      end
    end

    context "when params is set and not valid" do
      let(:params) { ActionController::Parameters.new(
        case_form: { name: "", email: "notanemail" }
      ).require(:case_form).permit(:name, :email)}

      context "and the form model has the values merged" do
        it "returns false" do
          case_form.assign_params(params)

          expect(case_form.valid_attributes?(params)).to be false
        end
      end

      context "and the form model does not have the values merged" do
        it "returns false" do
          expect(case_form.valid_attributes?(params)).to be false
        end
      end
    end
  end
end
