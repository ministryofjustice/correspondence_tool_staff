require "rails_helper"

describe NewOverturnedICOCaseService do
  describe ".new" do
    context "when id of non existent case" do
      it "raises" do
        expect {
          described_class.new(9_123_456)
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe "#call" do
    context "when original ico appeal case type is  not ICO" do
      let(:service)                 { described_class.new(original_ico_appeal.id) }
      let(:original_ico_appeal)     { create :case }
      let(:original_case)           { create :case }

      before do
        allow(original_ico_appeal).to receive(:original_case).and_return(original_case)
        service.call
      end

      it "adds an error to the original case" do
        expect(service.original_ico_appeal.errors[:base]).to eq ["Invalid ICO appeal case type"]
      end

      it "sets the error flag" do
        expect(service.error?).to be true
      end
    end

    context "when original ico appeal case type is Case::ICO::SAR" do
      let(:original_ico_appeal)     { create :ico_sar_case, original_case: }
      let(:original_case)           { create :sar_case, subject: "My SAR case", reply_method: "send_by_email", email: "me@moj.com" }
      let(:service)                 { described_class.new(original_ico_appeal.id) }

      before do
        service.call
      end

      it "sets the new overturned case to be a Case::OverturnedICO::SAR" do
        expect(service.overturned_ico_case).to be_instance_of(Case::OverturnedICO::SAR)
      end

      it "is success" do
        expect(service.success?).to be true
      end

      it "sets the original_case" do
        expect(service.overturned_ico_case.original_case).to eq original_case
      end

      it "sets the original_ico_appeal" do
        expect(service.overturned_ico_case.original_ico_appeal).to eq original_ico_appeal
      end

      it "copies the ico officer name from the original appeal" do
        expect(service.overturned_ico_case.ico_officer_name).to eq original_ico_appeal.ico_officer_name
      end

      describe "setting the reply method" do
        context "and original case send_by_email" do
          it "sets the reply method" do
            expect(service.overturned_ico_case.reply_method).to eq "send_by_email"
          end

          it "sets the email address" do
            expect(service.overturned_ico_case.email).to eq "me@moj.com"
          end
        end

        context "and original case sent by post" do
          let(:address) { "Ministry of Justice\n102 Petty France\nLondon\nSW1H 9AJ" }

          it "sets the reply method and postal address" do
            my_original_case = create :sar_case, reply_method: "send_by_post", postal_address: address
            my_ico_appeal = create :ico_sar_case, original_case: my_original_case
            my_service = described_class.new(my_ico_appeal.id)
            my_service.call

            expect(my_service.overturned_ico_case.reply_method).to eq "send_by_post"
            expect(my_service.overturned_ico_case.postal_address).to eq address
          end
        end
      end
    end

    context "when original case type is Case::ICO::FOI" do
      let(:original_case)       { original_ico_appeal.original_case }
      let(:original_ico_appeal) { create :closed_ico_foi_case }
      let(:service)             { described_class.new(original_ico_appeal.id) }

      before do
        allow_any_instance_of(Case::ICO::FOI) # rubocop:disable RSpec/AnyInstance
          .to receive(:original_case).and_return(original_case)
        service.call
      end

      it "sets the new overturned case to be a Case::OverturnedICO::SAR" do
        expect(service.overturned_ico_case).to be_instance_of(Case::OverturnedICO::FOI)
      end

      it "is success" do
        expect(service.success?).to be true
      end

      it "sets the original_case" do
        expect(service.overturned_ico_case.original_case).to eq original_case
      end

      it "sets the original_ico_appeal" do
        expect(service.overturned_ico_case.original_ico_appeal).to eq original_ico_appeal
      end

      describe "setting the reply method" do
        context "and original case sent_by_email" do
          it "sets the reply method" do
            expect(service.overturned_ico_case.reply_method).to eq "send_by_email"
          end

          it "sets the email address" do
            expect(service.overturned_ico_case.email).to eq original_case.email
          end
        end

        context "and original case sent by post" do
          let(:original_case)       { create :foi_case, :case_sent_by_post }

          it "sets the reply method and postal address" do
            expect(service.overturned_ico_case.reply_method).to eq "send_by_post"
            expect(service.overturned_ico_case.postal_address)
              .to eq original_case.postal_address
          end
        end
      end
    end
  end
end
