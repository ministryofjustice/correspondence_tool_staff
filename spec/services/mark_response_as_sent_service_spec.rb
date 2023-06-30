require "rails_helper"

describe MarkResponseAsSentService do
  let(:ico_kase) do
    find_or_create :approved_ico_foi_case,
                   received_date: 15.days.ago,
                   internal_deadline: 15.days.ago,
                   external_deadline: 5.days.ago
  end
  let(:foi_kase) do
    find_or_create :ready_to_send_case,
                   received_date: 15.days.ago,
                   internal_deadline: 15.days.ago,
                   external_deadline: 5.days.ago
  end
  let(:disclosure_specialist)   { find_or_create :disclosure_specialist }
  let(:responder)               { foi_kase.responder }

  describe "FOI" do
    let(:service) { described_class.new(foi_kase, responder, params) }

    context "when invalid date" do
      context "and blank date" do
        let(:params) do
          {
            date_responded_dd: "",
            date_responded_mm: "",
            date_responded_yyyy: "",
          }
        end

        it "sets result to :error" do
          service.call
          expect(service.result).to eq :error
        end

        it "sets the error" do
          service.call
          expect(foi_kase.errors[:date_responded]).to eq ["cannot be blank"]
        end
      end

      context "and impossible date" do
        let(:params) do
          {
            date_responded_dd: "33",
            date_responded_mm: "15",
            date_responded_yyyy: "2017",
          }
        end

        it "sets result to :error" do
          service.call
          expect(service.result).to eq :error
        end

        it "sets the error" do
          service.call
          expect(foi_kase.errors[:date_responded]).to eq ["cannot be blank"]
        end
      end

      context "and future date" do
        let(:response_date) { 10.days.from_now }
        let(:params)  do
          {
            date_responded_dd: response_date.day.to_s,
            date_responded_mm: response_date.month.to_s,
            date_responded_yyyy: response_date.year.to_s,
          }
        end

        it "sets result to :error" do
          service.call
          expect(service.result).to eq :error
        end

        it "sets the error" do
          service.call
          expect(foi_kase.errors[:date_responded]).to eq ["cannot be in the future"]
        end
      end
    end

    context "when valid date" do
      let(:response_date) { 5.days.ago }
      let(:params) do
        {
          date_responded_dd: response_date.day.to_s,
          date_responded_mm: response_date.month.to_s,
          date_responded_yyyy: response_date.year.to_s,
        }
      end

      it "sets result to :ok" do
        service.call
        expect(service.result).to eq :ok
      end

      it "calls the state machine to respond" do
        expect(foi_kase).to receive(:respond).with(responder)
        service.call
      end

      it "updates the date responded" do
        service.call
        expect(foi_kase.date_responded).to eq response_date.to_date
      end
    end
  end

  describe "ICO" do
    let(:service) { described_class.new(ico_kase, disclosure_specialist, params) }

    context "when invalid date" do
      context "and no date" do
        let(:params) do
          {
            date_responded_dd: "",
            date_responded_mm: "",
            date_responded_yyyy: "",
          }
        end

        it "sets result to :error" do
          service.call
          expect(service.result).to eq :error
        end

        it "sets the error" do
          service.call
          expect(ico_kase.errors[:date_responded]).to eq ["cannot be blank"]
        end
      end

      context "and impossible date" do
        let(:params) do
          {
            date_responded_dd: "33",
            date_responded_mm: "15",
            date_responded_yyyy: "2017",
          }
        end

        it "sets result to :error" do
          service.call
          expect(service.result).to eq :error
        end

        it "sets the error" do
          service.call
          expect(ico_kase.errors[:date_responded]).to include "Invalid date"
        end
      end

      context "and future date" do
        let(:response_date) { 10.days.from_now }
        let(:params)  do
          {
            date_responded_dd: response_date.day.to_s,
            date_responded_mm: response_date.month.to_s,
            date_responded_yyyy: response_date.year.to_s,
          }
        end

        it "sets result to :error" do
          service.call
          expect(service.result).to eq :error
        end

        it "sets the error" do
          service.call
          expect(ico_kase.errors[:date_responded]).to eq ["cannot be in the future"]
        end
      end
    end

    context "when valid date" do
      let(:params) do
        {
          date_responded_dd: response_date.day.to_s,
          date_responded_mm: response_date.month.to_s,
          date_responded_yyyy: response_date.year.to_s,
        }
      end

      context "and responded in time" do
        let(:response_date)     { 5.days.ago }

        it "sets result to :ok" do
          service.call
          expect(service.result).to eq :ok
        end

        it "calls the state machine to respond" do
          expect(ico_kase).to receive(:respond).with(disclosure_specialist)
          service.call
        end

        it "updates the date responded" do
          service.call
          expect(ico_kase.date_responded).to eq response_date.to_date
        end

        it "saves the record with the new date" do
          service.call
          ico_kase.reload
          expect(ico_kase.date_responded).to eq response_date.to_date
        end
      end

      context "and responded late" do
        let(:response_date) { Time.zone.today }

        it "updates the date responded in the model" do
          service.call
          expect(ico_kase.date_responded).to eq response_date.to_date
        end

        it "does save the record" do
          service.call
          ico_kase.reload
          expect(ico_kase.date_responded).to eq response_date.to_date
        end

        it "sets result to :late" do
          service.call
          expect(service.result).to eq :late
        end
      end
    end
  end
end
