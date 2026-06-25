require "rails_helper"

describe Admin::DashboardController do
  let(:admin)         { create :admin }
  let(:manager)       { create :manager }
  let!(:search_query) { create :search_query }
  let!(:list_query)   { create :list_query }

  let!(:personal_information_requests) do
    [
      create(:personal_information_request),
      create(:personal_information_request, :deleted),
      create(:personal_information_request, :processed),
    ]
  end

  describe "#feedback" do
    before do
      sign_in admin
      get :feedback
    end

    it "renders the index view" do
      expect(request.path).to eq("/admin/dashboard/feedback")
    end
  end

  describe "#feedback_year" do
    before do
      sign_in admin
      get :feedback_year, params: { year: 2023 }
    end

    it "renders the show view" do
      expect(request.path).to eq("/admin/dashboard/feedback/2023")
    end
  end

  describe "#list_queries" do
    before do
      sign_in admin
      get :list_queries
    end

    it "renders the index view" do
      expect(request.path).to eq("/admin/dashboard/list_queries")
    end

    it "has search queries" do
      expect(controller.queries).to eq [list_query]
    end
  end

  describe "#search_queries" do
    before do
      sign_in admin
      get :search_queries
    end

    it "renders the search_queries view" do
      expect(request.path).to eq("/admin/dashboard/search_queries")
    end

    it "has search queries" do
      expect(controller.queries).to eq [search_query]
    end
  end

  describe "#system" do
    before do
      sign_in admin
      get :system
    end

    it "renders the system view" do
      expect(request.path).to eq("/admin/dashboard/system")
    end

    it "has Git version SHA" do
      git_sha = assigns(:version)
      expect(git_sha).to be_present
      expect(git_sha).to eq Settings.git_commit
    end
  end

  describe "#bank_holidays" do
    before { sign_in admin }

    it "renders the page" do
      get :bank_holidays
      expect(response).to have_http_status(:ok)
      expect(request.path).to eq("/admin/dashboard/bank-holidays")
    end
  end

  describe "#personal_information_requests" do
    before do
      sign_in admin
      get :personal_information_requests
    end

    it "renders the personal_information_requests view" do
      expect(request.path).to eq("/admin/dashboard/personal_information_requests")
    end

    it "has personal information requests" do
      expect(controller.personal_information_requests).to match_array(personal_information_requests)
    end
  end

  describe "#events" do
    let(:email_sent_event) do
      Events::EmailSent.build(
        recipient: "test@test.com",
        subject: "Subject Access Request - 12345",
        category: "commissioning_document",
        email_type: "commissioning_email",
        recipient_type: "external",
        case_number: "12345",
      )
    end

    let(:email_failed_event) do
      Events::EmailFailed.build(
        recipient: "test@test.com",
        subject: "Subject Access Request - 12345",
        category: "commissioning_document",
        email_type: "commissioning_email",
        recipient_type: "external",
        case_number: "12345",
        status: "permanent-failure",
        notify_id: "notify-123",
      )
    end

    let(:rpi_failed_event) do
      Events::RpiUnprocessed.build(
        personal_information_request_id: 1,
        submission_id: "submission-123",
        schema: "1",
        error_message: "Failed to process RPI",
      )
    end

    before do
      Rails.configuration.event_store.publish(email_sent_event, stream_name: "email_events")
      Rails.configuration.event_store.publish(email_failed_event, stream_name: "email_events")
      Rails.configuration.event_store.publish(rpi_failed_event, stream_name: "rpi_events")

      sign_in admin
      get :events
    end

    it "renders the events view" do
      expect(request.path).to eq("/admin/dashboard/events")
    end

    it "has events" do
      expect(assigns(:email_failed_events_count)).to eq 1
      expect(assigns(:rpi_failed_events_count)).to eq 1
    end

    describe "the presented events (SystemLogEventPresenter)" do
      let(:events) { assigns(:events) }

      def presenter_for(name)
        events.find { |event| event.name == name }
      end

      it "presents every published event" do
        expect(events).to all(be_a(SystemLogEventPresenter))
        expect(events.map(&:name))
          .to contain_exactly("Email sent", "Email failed", "Rpi unprocessed")
      end

      context "with an email failed event" do
        subject(:presenter) { presenter_for("Email failed") }

        it "flags it as an email failed event" do
          expect(presenter.email_failed_event?).to be true
        end

        it "exposes the recipient" do
          expect(presenter.recipient).to eq "test@test.com"
        end

        it "exposes the subject" do
          expect(presenter.subject).to eq "Subject Access Request - 12345"
        end

        it "humanises the failure details into a pipe-separated summary" do
          expect(presenter.details).to eq(
            "Commissioning document | Commissioning email | Permanent failure | " \
            "External | Case 12345 | Notify notify-123",
          )
        end
      end

      context "with an email sent event" do
        subject(:presenter) { presenter_for("Email sent") }

        it "is not treated as an email failed event" do
          expect(presenter.email_failed_event?).to be false
        end

        it "does not expose a recipient or subject" do
          expect(presenter.recipient).to be_nil
          expect(presenter.subject).to be_nil
        end

        it "renders the raw event data as JSON for the details" do
          expect(presenter.details)
            .to include("test@test.com")
            .and include("commissioning_document")
        end
      end

      context "with an rpi unprocessed event" do
        subject(:presenter) { presenter_for("Rpi unprocessed") }

        it "flags it as an rpi failed event" do
          expect(presenter.rpi_failed_event?).to be true
        end

        it "renders the raw event data as JSON for the details" do
          expect(presenter.details).to include("submission-123")
        end
      end
    end
  end
end
