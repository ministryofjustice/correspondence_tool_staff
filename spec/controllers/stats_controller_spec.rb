require "rails_helper"
require File.join(Rails.root, "db", "seeders", "report_type_seeder")

RSpec.describe StatsController, type: :controller do
  let(:manager) { find_or_create :disclosure_bmt_user }
  let(:branston_user) { find_or_create :branston_user }

  before do
    sign_in manager
    ReportType.delete_all
  end

  before(:all) do
    ReportTypeSeeder.new.seed!
  end

  describe "#show" do
    let!(:r005_report_type) { create :report_type, :r005 }

    it "authorizes" do
      expect { get :show, params: { id: ReportType.first.id  } }
        .to require_permission(:can_download_stats?)
          .with_args(manager, Case::Base)
    end

    context "there is no already-generated report" do
      let(:report_type) { find_or_create :report_type, :r005 }

      it "sends the generated report as an attachment" do
        Timecop.freeze(Date.new(2019, 3, 22)) do
          get :show, params: { id: report_type.id }

          expect(response.headers["Content-Disposition"])
            .to have_content 'attachment; filename="r005_monthly_performance_report.xlsx"'
        end
      end
    end
  end

  describe "#new" do
    context "signed in manager" do
      before do
        sign_in manager
        find_or_create :report_type, :r007
      end

      it "authorizes" do
        expect { get :new }
          .to require_permission(:can_download_stats?)
            .with_args(manager, Case::Base)
      end

      it "sets @report" do
        get :new
        expect(assigns(:report)).to be_new_record
      end

      it "sets @custom_reports_foi" do
        get :new
        expect(assigns(:custom_reports_foi)).to eq ReportType.custom.foi
      end

      it "sets @custom_reports_sar" do
        get :new
        expect(assigns(:custom_reports_sar)).to eq ReportType.custom.sar
      end

      it "sets @correspondence_types" do
        get :new
        expected = %w[FOI SAR SAR_INTERNAL_REVIEW CLOSED_CASES]
        expect(assigns(:correspondence_types).map(&:abbreviation)).to eq expected
      end

      it "renders the template" do
        get :new
        expect(response).to render_template(:new)
      end
    end

    context "signed in branston user" do
      before do
        sign_in branston_user
        find_or_create :report_type, :r007
      end

      it "authorizes" do
        expect { get :new }
          .to require_permission(:can_download_stats?)
            .with_args(branston_user, Case::Base)
      end

      it "sets @report" do
        get :new
        expect(assigns(:report)).to be_new_record
      end

      it "sets @custom_reports_offender_sar" do
        get :new
        expect(assigns(:custom_reports_offender_sar)).to eq ReportType.custom.offender_sar
      end

      it "sets @custom_reports_offender_sar_complaint" do
        get :new
        expect(assigns(:custom_reports_offender_sar_complaint)).to eq ReportType.custom.offender_sar_complaint
      end

      it "sets @correspondence_types" do
        get :new
        expected = %w[OFFENDER_SAR OFFENDER_SAR_COMPLAINT]
        expect(assigns(:correspondence_types).map(&:abbreviation)).to match_array expected
      end

      it "renders the template" do
        get :new
        expect(response).to render_template(:new)
      end
    end
  end

  describe "#create" do
    let(:report_type) { find_or_create :report_type, :r003 }

    let(:params) do
      {
        report: {
          correspondence_type: "FOI",
          report_type_id: report_type.id,
          period_start_dd: Date.yesterday.day,
          period_start_mm: Date.yesterday.month,
          period_start_yyyy: Date.yesterday.year,
          period_end_dd: Date.today.day,
          period_end_mm: Date.today.month,
          period_end_yyyy: Date.today.year,
        },
      }
    end

    let(:report) do
      create :r003_report, period_start: Date.yesterday, period_end: Date.today
    end

    let(:dummy_report_type) do
      double(to_csv: [], persist_results?: false, etl?: false, background_job?: false,
             results: {}, report_format: "csv")
    end

    it "authorizes" do
      expect { post :create, params: }
        .to require_permission(:can_download_stats?)
          .with_args(manager, Case::Base)
    end

    it "runs the report" do
      expect(Report).to receive(:new).and_return(report)
      allow(report).to receive(:run).and_return(dummy_report_type)
      allow(dummy_report_type).to receive(:filename).and_return("test.csv")
      allow(dummy_report_type).to receive(:user).and_return(manager)
      allow(dummy_report_type).to receive(:period_start).and_return(Date.yesterday)
      allow(dummy_report_type).to receive(:period_end).and_return(Date.today)

      post(:create, params:)
      expect(report).to have_received(:run).with(period_start: Date.yesterday,
                                                 period_end: Date.today, user: manager, report_guid: report.guid)
    end

    context "invalid params passed in" do
      let(:params) do
        {
          report: {
            correspondence_type: "FOI",
            report_type_id: report_type.id,
            period_start_dd: nil,
            period_start_mm: nil,
            period_start_yyyy: nil,
            period_end_dd: nil,
            period_end_mm: nil,
            period_end_yyyy: nil,
          },
        }
      end

      context "correspondence type and report type radio buttons not selected" do
        let(:params) do
          {
            report: {
              period_start_dd: nil,
              period_start_mm: nil,
              period_start_yyyy: nil,
              period_end_dd: nil,
              period_end_mm: nil,
              period_end_yyyy: nil,
            },
          }
        end

        it "marks an error for missing correspondence type but  not report type" do
          post(:create, params:)
          expect(assigns(:report).errors[:correspondence_type]).to eq ["cannot be blank"]
          expect(assigns(:report).errors[:report_type]).not_to be_present
        end
      end

      context "correspondence type present but no report type id" do
        let(:params) do
          {
            report: {
              correspondence_type: "FOI",
              period_start_dd: nil,
              period_start_mm: nil,
              period_start_yyyy: nil,
              period_end_dd: nil,
              period_end_mm: nil,
              period_end_yyyy: nil,
            },
          }
        end

        it "marks the report type as being in error" do
          post(:create, params:)
          expect(assigns(:report).errors[:report_type_id]).to eq ["cannot be blank"]
        end
      end

      it "sets @report to the values that were passed in" do
        post(:create, params:)
        expect(assigns(:report)).to be_new_record
      end

      it "sets @custom_reports_foi" do
        post(:create, params:)
        expect(assigns(:custom_reports_foi)).to eq ReportType.custom.foi
      end

      it "sets @custom_reports_sar" do
        post(:create, params:)
        expect(assigns(:custom_reports_sar)).to eq ReportType.custom.sar
      end

      it "sets @custom_reports_offender_sar" do
        post(:create, params:)
        expect(assigns(:custom_reports_offender_sar)).to eq ReportType.custom.offender_sar
      end

      it "sets @custom_reports_offender_sar_complaint" do
        post(:create, params:)
        expect(assigns(:custom_reports_offender_sar_complaint)).to eq ReportType.custom.offender_sar_complaint
      end

      it "sets @custom_reports_closed_cases" do
        post(:create, params:)
        expect(assigns(:custom_reports_closed_cases)).to eq ReportType.closed_cases_report
      end

      it "renders the template" do
        post(:create, params:)
        expect(response).to render_template(:new)
      end

      it "returns 2 errors (dates are missing)" do
        post(:create, params:)
        expect(assigns(:report).errors.count).to eq 2
      end
    end

    context "etl - closed cases report" do
      let(:report_type) { find_or_create :report_type, :r007 }

      let(:params) do
        {
          report: {
            correspondence_type: "CLOSED_CASES",
            report_type_id: report_type.id,
            period_start_dd: Date.yesterday.day,
            period_start_mm: Date.yesterday.month,
            period_start_yyyy: Date.yesterday.year,
            period_end_dd: Date.today.day,
            period_end_mm: Date.today.month,
            period_end_yyyy: Date.today.year,
          },
        }
      end

      it "creates a new report" do
        expect {
          post(:create, params:)
        }.to change(Report.all, :size).by(1)

        report = Report.last
        expect(report.status).to eq Stats::BaseReport::WAITING
      end
    end
  end

  describe "#index" do
    before do
      ReportTypeSeeder.new.seed!
    end

    after do
      ReportType.delete_all
    end

    it "authorizes" do
      expect { get :index }
        .to require_permission(:can_download_stats?)
          .with_args(manager, Case::Base)
    end

    it "sets @reports" do
      get :index

      available_standard_reports = assigns(:reports)
      expect(available_standard_reports).to match_array ReportType.where(abbr: %w[R005 R105])
    end

    it "renders the template" do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe "#download_custom" do
    context "non-etl" do
      let!(:report) { create :report }

      it "authorizes" do
        expect { get :download_custom, params: { id: report.id } }
          .to require_permission(:can_download_stats?)
            .with_args(manager, Case::Base)
      end

      it "responds with a csv file" do
        file_options = {
          filename: report.filename,
          disposition: :attachment,
        }

        expect(@controller).to receive(:send_data)
          .with(report.report_data, file_options) { |_csv, _options|
            @controller.render body: :nil
          }

        get :download_custom, params: { id: report.id }
      end
    end
  end
end
