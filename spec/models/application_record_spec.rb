require "rails_helper"

RSpec.describe ApplicationRecord, type: :model do
  describe "#valid_attributes?" do
    subject { klass.new(attributes) }

    let(:klass) do
      Class.new(Feedback) do
        attribute :fave_band, :string
        attribute :fave_colour, :string
        attribute :completed, :boolean

        validates :fave_band, presence: true, if: -> { completed? }
        validates :fave_colour, presence: true, unless: -> { completed? }
      end
    end

    context "when all attributes are valid" do
      let(:attributes) { { comment: "nice", email: "test@example.com", fave_band: "The Beatles", fave_colour: "Blue", completed: true } }

      it { is_expected.to be_valid_attributes(attributes) }
    end

    context "when some attributes are invalid" do
      let(:attributes) { { comment: "nice", "email" => "test@example.com", fave_band: nil, "fave_colour" => "" } }

      it { is_expected.not_to be_valid_attributes(attributes) }

      context "with conditional validations" do
        it "executes `if` condition" do
          invalid_attributes = attributes.merge(completed: true)

          subject = klass.new(invalid_attributes)
          subject.valid_attributes?(invalid_attributes)

          expect(subject.errors.attribute_names).to eq([:fave_band])
        end

        it "executes `unless` condition" do
          invalid_attributes = attributes.merge(completed: false)

          subject = klass.new(invalid_attributes)
          subject.valid_attributes?(invalid_attributes)

          expect(subject.errors.attribute_names).to eq([:fave_colour])
        end
      end
    end

    context "when some attributes are missing" do
      let(:attributes) { { comment: "nice", email: "test@example.com", completed: true } }

      it "does not validate missing attributes" do
        subject = klass.new(attributes)
        subject.valid_attributes?(attributes)

        expect(subject.errors.attribute_names).to eq([])
      end
    end
  end
end
