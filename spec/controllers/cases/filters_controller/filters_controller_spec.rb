require "rails_helper"

describe Cases::FiltersController, type: :controller do
  let(:manager)               { find_or_create :disclosure_specialist_bmt }
  let(:responder)             { find_or_create :foi_responder }
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:responding_team)       { responder.responding_teams.first }
  let(:team_dacu_disclosure)  { find_or_create :team_dacu_disclosure }
  let(:manager_approver)      { create :manager_approver }
  let(:responding_team)       { responder.responding_teams.first }

  let(:flagged_case) do
    create(
      :assigned_case,
      :flagged,
      responding_team:,
      approving_team: team_dacu_disclosure,
    )
  end

  describe "#my_open" do
    context "as an anonymous user" do
      it "be redirected to signin if trying to list of questions" do
        get :my_open, params: { tab: "in_time" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "without stubs" do
      let!(:closed_case) { create(:closed_case) }
      let!(:active_case) { flagged_case }

      before do
        sign_in manager_approver
      end

      it "gets only incoming cases" do
        get :incoming
        expect(assigns(:cases)).not_to match_array([closed_case, active_case])
        expect(assigns(:cases)).to match_array([active_case])
      end
    end

    context "as an authenticated disclosure_specialist" do
      before do
        sign_in disclosure_specialist
      end

      it "assigns the result set from the finder provided by GlobalNavManager" do
        stub_current_case_finder_cases_with(:my_open_cases_result)
        get :my_open, params: { tab: "in_time" }
        expect(assigns(:cases)).to eq :my_open_cases_result
      end

      it "passes page param to the paginator" do
        gnm = stub_current_case_finder_cases_with(:my_open_cases_result)
        get :my_open, params: { page: "our_page", tab: "in_time" }
        expect(gnm.current_page_or_tab.cases.by_deadline)
          .to have_received(:page).with("our_page")
      end

      it 'sets @current_tab_name to all cases for "All open cases tab"' do
        stub_current_case_finder_cases_with(:my_open_cases_result)
        get :my_open, params: { tab: "in_time" }
        expect(assigns(:current_tab_name)).to eq "my_cases"
      end

      context "html request" do
        it "renders the index template" do
          stub_current_case_finder_cases_with(:my_open_cases_result)
          get :my_open, params: { tab: "in_time" }
          expect(response).to render_template(:index)
        end
      end

      context "csv request" do
        it "downloads a csv file" do
          expect(CSVGenerator).to receive(:filename).with("my-open").and_return("abc.csv")

          get :my_open, params: { tab: "in_time" }, format: "csv"
          expect(response.status).to eq 200
          expect(response.header["Content-Disposition"]).to eq 'attachment; filename="abc.csv"'
          expect(response.body).to eq CSV.generate_line(CSVExporter::CSV_COLUMN_HEADINGS)
        end
      end
    end
  end

  describe "#incoming" do
    context "as an anonymous user" do
      it "be redirected to signin if trying to list of questions" do
        get :incoming
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as an authenticated disclosure_specialist" do
      before do
        sign_in disclosure_specialist
      end

      it "assigns the result set from the finder provided by GlobalNavManager" do
        stub_current_case_finder_cases_with(:incoming_cases_result)
        get :incoming
        expect(assigns(:cases)).to eq :incoming_cases_result
      end

      it "renders the incoming_cases template" do
        get :incoming
        expect(response).to render_template(:incoming)
      end

      it "passes page param to the paginator" do
        gnm = stub_current_case_finder_cases_with(:incoming_cases_result)
        get :incoming, params: { page: "our_page" }
        expect(gnm.current_page_or_tab.cases.by_deadline)
          .to have_received(:page).with("our_page")
      end
    end
  end

  describe "#deleted" do
    let!(:active_kase) { create(:case) }

    # This case should be outside the 6 month threshold for downloading
    let!(:ancient_deleted_kase) do
      Timecop.travel(7.months.ago) do
        create(:case, :deleted_case)
      end
    end

    let!(:deleted_sar_kase) { create(:sar_case, :deleted_case) }

    context "as a manager" do
      before { sign_in manager }

      it "retrieves only deleted cases" do
        deleted_kase = create(:assigned_case, created_at: 1.day.ago, responding_team:)
        deleted_kase.update! deleted: true, reason_for_deletion: "Needs to go"

        get :deleted, format: :csv
        expect(assigns(:cases)).to eq([deleted_sar_kase, deleted_kase])
      end
    end

    context "as a lesser user" do
      before { sign_in responder }

      it "retrieves only deleted cases I am supposed to see" do
        deleted_kase = create(:assigned_case, responding_team:)
        deleted_kase.update! deleted: true, reason_for_deletion: "Needs to go"
        get :deleted, format: :csv
        expect(assigns(:cases)).to eq([deleted_kase])
      end
    end
  end

  describe "#closed" do
    context "as a manager" do
      before { sign_in manager }

      it "assigns cases returned by CaseFinderService" do
        stub_current_case_finder_for_closed_cases_with(:closed_cases_result)
        get :closed
        expect(assigns(:cases)).to eq :closed_cases_result
      end

      it "passes page param to the paginator" do
        gnm = stub_current_case_finder_for_closed_cases_with(:closed_cases_result)
        get :closed, params: { page: "our_page" }
        expect(gnm.current_page_or_tab.cases.by_last_transitioned_date)
          .to have_received(:page).with("our_page")
      end

      context "html format" do
        it "renders the closed cases page" do
          get :closed
          expect(response).to render_template :closed
        end
      end

      context "csv format" do
        let!(:gnm) { stub_current_case_finder_for_closed_cases_with(:closed_cases_result) }
        let(:record) { double }

        before do
          expect(CSVGenerator).to receive(:filename).with("closed").and_return("abc.csv")
          get :closed, format: "csv"
          expect(response.status).to eq 200
        end

        it "generates a file and downloads it" do
          expect(gnm.current_page_or_tab.cases.by_last_transitioned_date).to receive(:each).and_yield(record)
          expect(record).to receive(:to_csv).and_return(%w[a csv line])

          expect(response.header["Content-Disposition"]).to eq 'attachment; filename="abc.csv"'
          expect(response.body).to eq "#{CSV.generate_line(CSVExporter::CSV_COLUMN_HEADINGS)}a,csv,line\n"
        end

        it "does not paginate the result set" do
          expect(gnm.current_page_or_tab.cases.by_last_transitioned_date)
            .not_to have_received(:page).with("our_page")
        end
      end
    end

    context "as an anonymous user" do
      context "html format" do
        it "be redirected to signin if trying to update a specific case" do
          get :closed
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "csv format" do
        it "prevents the user from downloading" do
          expect(CSVGenerator).not_to receive(:new)

          get :closed, format: "csv"
          expect(response.status).to eq 401
          expect(response.header["Content-Type"]).to eq "text/csv; charset=utf-8"
          expect(response.body).to eq "You need to sign in or contact the Disclosure Team at data.access@Justice.gov.uk to request access."
        end
      end
    end
  end

  describe "#retention" do
    context "tab ready_for_removal" do
      context "as an anonymous user" do
        it "be redirected to signin if trying to access the page" do
          get :retention, params: { tab: "ready_for_removal" }
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "as a manager" do
        before do
          sign_in manager

          allow_any_instance_of(GlobalNavManager).to receive(:current_page_or_tab).and_return(page_double)
          allow_any_instance_of(CaseSearchService).to receive(:call).and_return(true)
        end

        let(:page_double) { double("page", name: "ready_for_removal").as_null_object }

        it "renders the retention cases page" do
          get :retention, params: { tab: "ready_for_removal" }
          expect(response).to render_template :retention
        end

        it "assigns the filter_crumbs" do
          get :retention, params: { tab: "ready_for_removal" }
          expect(assigns(:filter_crumbs)).not_to be_nil
        end

        it "assigns the current_tab_name" do
          get :retention, params: { tab: "ready_for_removal" }
          expect(assigns(:current_tab_name)).to eq("retention_ready_for_removal")
        end
      end
    end

    context "tab pending_removal" do
      context "as an anonymous user" do
        it "be redirected to signin if trying to access the page" do
          get :retention, params: { tab: "pending_removal" }
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "as a manager" do
        before do
          sign_in manager

          allow_any_instance_of(GlobalNavManager).to receive(:current_page_or_tab).and_return(page_double)
          allow_any_instance_of(CaseSearchService).to receive(:call).and_return(true)
        end

        let(:page_double) { double("page", name: "pending_removal").as_null_object }

        it "renders the retention cases page" do
          get :retention, params: { tab: "pending_removal" }
          expect(response).to render_template :retention
        end

        it "assigns the filter_crumbs" do
          get :retention, params: { tab: "pending_removal" }
          expect(assigns(:filter_crumbs)).not_to be_nil
        end

        it "assigns the current_tab_name" do
          get :retention, params: { tab: "pending_removal" }
          expect(assigns(:current_tab_name)).to eq("retention_pending_removal")
        end
      end
    end
  end

  # Utility methods

  def stub_current_case_finder_for_closed_cases_with(result)
    pager = double "Kaminari Pager", decorate: result
    cases_by_last_transitioned_date = double "ActiveRecord Cases by last transitioned", page: pager
    cases = double "ActiveRecord Cases", by_last_transitioned_date: cases_by_last_transitioned_date
    page = instance_double(GlobalNavManager::Page, cases:)
    gnm = instance_double GlobalNavManager, current_page_or_tab: page
    allow(cases_by_last_transitioned_date).to receive(:limit).and_return(cases_by_last_transitioned_date)
    allow(cases).to receive(:includes).and_return(cases)
    allow(cases).to receive(:size).and_return(10)
    allow(cases).to receive(:count).and_return(10)
    allow(GlobalNavManager).to receive(:new).and_return gnm
    gnm
  end

  def stub_current_case_finder_cases_with(result)
    pager = double "Kaminari Pager", decorate: result
    cases_by_deadline = double "ActiveRecord Cases by Deadline", page: pager
    cases = double "ActiveRecord Cases", by_deadline: cases_by_deadline

    allow(cases).to receive(:includes).and_return(cases)
    allow(cases).to receive(:size).and_return(10)
    allow(cases).to receive(:count).and_return(10)
    allow(cases.by_deadline).to receive(:decorate).and_return(cases)

    tab1 = instance_double GlobalNavManager::Tab
    tab2 = instance_double GlobalNavManager::Tab
    tabs = [tab1, tab2]

    page = instance_double(GlobalNavManager::Page, cases:)
    gnm = instance_double GlobalNavManager, current_page_or_tab: page

    allow(GlobalNavManager).to receive(:new).and_return gnm
    allow(gnm).to receive(:current_page).and_return page
    allow(page).to receive(:tabs).and_return tabs

    tabs.each do |tab|
      allow(tab).to receive(:cases).and_return cases
      allow(tab).to receive(:set_count).and_return nil
    end

    gnm
  end
end
