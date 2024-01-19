require "rails_helper"
  describe ViewsHelper, type: :helper do
    include ViewsHelper


    describe "Creating an offender sar" do
      context "adding a rejected offender sar case" do
        describe Case, type: :model do

          it "creates an offender object" do
            # Use the factory to create an instance of Case::Sar::Offender
            kase = FactoryBot.build(Case::Sar::Offender)

            headings = get_headings(kase, "rejections", OFFENDER_SAR")

            expect(headings).to eq("Create a rejected offender sar")
          end
        end
      end
    end
  end
