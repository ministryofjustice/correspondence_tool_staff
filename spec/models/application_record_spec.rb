require "rails_helper"

RSpec.describe ApplicationRecord, type: :model do
  describe "#valid_attributes?" do
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
      let(:valid_attributes) do
        { comment: "nice", email: "test@example.com", fave_band: "The Beatles", fave_colour: "Blue", completed: true }
      end

      it "returns true" do
        my_feedback = klass.new(valid_attributes)
        expect(my_feedback.valid_attributes?(valid_attributes)).to be true
      end
    end

    context "when some attributes are invalid" do
      let(:invalid_attributes) do
        { comment: "nice", "email" => "test@example.com", fave_band: nil, "fave_colour" => "" }
      end

      it "returns false" do
        my_feedback = klass.new(invalid_attributes)
        expect(my_feedback.valid_attributes?(invalid_attributes)).to be false
      end

      context "with conditional validations" do
        it "executes `if` condition" do
          my_feedback = klass.new(invalid_attributes.merge(completed: true))
          my_feedback.valid_attributes?(invalid_attributes.merge(completed: true))

          expect(my_feedback.errors.map(&:attribute)).to eq([:fave_band])
        end

        it "executes `unless` condition" do
          my_feedback = klass.new(invalid_attributes.merge(completed: false))
          my_feedback.valid_attributes?(invalid_attributes.merge(completed: false))

          expect(my_feedback.errors.map(&:attribute)).to eq([:fave_colour])
        end
      end
    end
  end
end
