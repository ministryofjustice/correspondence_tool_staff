require "rails_helper"
  describe ViewsHelper, type: :helper do
    include ViewsHelper


    describe "Creating an offender sar" do
      context "adding a rejected offender sar case" do
        describe Case, type: :model do

          it "creates an offender object" do
            # Use the factory to create an instance of Case::Sar::Offender
            kase = FactoryBot.build(:case)

            # Assuming get_headings returns a string
            headings = get_headings(kase, "OFFENDER_SAR")

            # Replace "Your expected title" with the actual expected result
            expect(headings).to eq("Create a rejected offender sar")
          end
        end
      end
    end
  end
