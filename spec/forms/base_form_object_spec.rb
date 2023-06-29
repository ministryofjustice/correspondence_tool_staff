require "rails_helper"

# rubocop:disable RSpec/SubjectStub
RSpec.describe BaseFormObject do
  subject(:base_form_object) { described_class.new }

  # rubocop:disable Rails/SaveBang
  describe "#save" do
    before do
      allow(base_form_object).to receive(:valid?).and_return(is_valid)
    end

    context "with a valid form" do
      let(:is_valid) { true }

      it "calls persist!" do
        expect(base_form_object).to receive(:persist!)
        base_form_object.save
      end
    end

    context "with an invalid form" do
      let(:is_valid) { false }

      it "does not call persist!" do
        expect(base_form_object).not_to receive(:persist!)
        base_form_object.save
      end

      it "returns false" do
        expect(base_form_object.save).to eq(false)
      end
    end
  end
  # rubocop:enable Rails/SaveBang

  describe "#persisted?" do
    it "always returns false" do
      expect(base_form_object.persisted?).to eq(false)
    end
  end

  describe "#new_record?" do
    it "always returns true" do
      expect(base_form_object.new_record?).to eq(true)
    end
  end

  describe "#to_key" do
    it "always returns nil" do
      expect(base_form_object.to_key).to be_nil
    end
  end

  describe "[]" do
    let(:record) { double("Record") } # rubocop:disable RSpec/VerifiedDoubles

    before do
      base_form_object.record = record
    end

    it "read the attribute directly without using the method" do
      expect(base_form_object).not_to receive(:record)
      expect(base_form_object[:record]).to eq(record)
    end
  end

  describe "[]=" do
    let(:record) { double("Record") } # rubocop:disable RSpec/VerifiedDoubles

    it "assigns the attribute directly without using the method" do
      expect(base_form_object).not_to receive(:record=)
      base_form_object[:record] = record
      expect(base_form_object.record).to eq(record)
    end
  end
end
# rubocop:enable RSpec/SubjectStub
