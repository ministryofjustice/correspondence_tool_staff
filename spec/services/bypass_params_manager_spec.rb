require "rails_helper"

describe BypassParamsManager do
  describe "#present?" do
    context "empty params" do
      it "returns false" do
        expect(described_class.new(empty_params).present?).to be false
      end
    end

    context "invalid bypass params" do
      it "returns true" do
        expect(described_class.new(invalid_message_no_bypass_params).present?).to be true
      end
    end
  end

  describe "#valid?" do
    context "empty params" do
      it "returns false" do
        expect(described_class.new(empty_params).valid?).to be false
      end
    end

    context "valid params" do
      it "returns true" do
        expect(described_class.new(valid_bypass_params).valid?).to be true
      end
    end

    context "invalid params" do
      it "returns false" do
        expect(described_class.new(invalid_message_no_bypass_params).valid?).to be false
      end
    end
  end

  describe "#approval_requested?" do
    context "empty params" do
      it "returns false" do
        expect(described_class.new(empty_params).approval_requested?).to be false
      end
    end

    context "invalid params" do
      it "returns false" do
        expect(described_class.new(invalid_message_no_bypass_params).approval_requested?).to be false
      end
    end

    context "valid params approval requested" do
      it "returns true" do
        expect(described_class.new(valid_no_bypass_params).approval_requested?).to be true
      end
    end

    context "valid params no approval requested" do
      it "returns false" do
        expect(described_class.new(valid_bypass_params).approval_requested?).to be false
      end
    end
  end

  def empty_params
    ActiveSupport::HashWithIndifferentAccess.new(
      {
        other_keys: "other_data",
      },
    )
  end

  def valid_bypass_params
    ActiveSupport::HashWithIndifferentAccess.new(
      {
        bypass_approval: {
          press_office_approval_required: "false",
          bypass_message: "section 12",
        },
      },
    )
  end

  def valid_no_bypass_params
    ActiveSupport::HashWithIndifferentAccess.new(
      {
        bypass_approval: {
          press_office_approval_required: "true",
          bypass_message: "",
        },
      },
    )
  end

  def invalid_message_no_bypass_params
    ActiveSupport::HashWithIndifferentAccess.new(
      {
        bypass_approval: {
          press_office_approval_required: "true",
          bypass_message: "section 12",
        },
      },
    )
  end

  def invalid_no_message_bypass_params
    ActiveSupport::HashWithIndifferentAccess.new(
      {
        bypass_approval: {
          press_office_approval_required: "false",
          bypass_message: "",
        },
      },
    )
  end
end
