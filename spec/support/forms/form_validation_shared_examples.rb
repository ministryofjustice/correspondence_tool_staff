RSpec.shared_examples "a date question form" do |options|
  subject(:form) { described_class.new(arguments) }

  let(:question_attribute) { options[:attribute_name] }

  let(:arguments) do
    {
      record:,
      "#{question_attribute}_yyyy" => date_value[0],
      "#{question_attribute}_mm" => date_value[1],
      "#{question_attribute}_dd" => date_value[2],
    }
  end

  let(:record) { instance_double("Record") }
  let(:date_value) { %w[2018 12 31] }

  describe "#save" do
    describe "date validation" do
      context "when date is not given" do
        let(:date_value) { [] }

        it "returns false" do
          expect(form.save).to be(false)
        end

        it "has a validation error on the field" do
          expect(form).not_to be_valid
          expect(form.errors.added?(question_attribute, :blank)).to eq(true)
        end
      end

      context "when day part of the date is missing" do
        let(:date_value) { %w[2018 12 nil] }

        it "returns false" do
          expect(form.save).to be(false)
        end

        # ActsAsGovUkDate gem will not set an error symbol but instead an error message
        it "has a validation error on the field" do
          expect(form).not_to be_valid
          expect(form.errors.added?(question_attribute, "Invalid date")).to eq(true)
        end
      end

      context "when month part of the date is missing" do
        let(:date_value) { %w[2018 nil 31] }

        it "returns false" do
          expect(form.save).to be(false)
        end

        # ActsAsGovUkDate gem will not set an error symbol but instead an error message
        it "has a validation error on the field" do
          expect(form).not_to be_valid
          expect(form.errors.added?(question_attribute, "Invalid date")).to eq(true)
        end
      end

      context "when date is invalid" do
        let(:date_value) { %w[2018 15 31] } # Month 15

        it "returns false" do
          expect(form.save).to be(false)
        end

        # ActsAsGovUkDate gem will not set an error symbol but instead an error message
        it "has a validation error on the field" do
          expect(form).not_to be_valid
          expect(form.errors.added?(question_attribute, "Invalid date")).to eq(true)
        end
      end
    end
  end
end
