require 'rails_helper'

RSpec.describe CasesController, type: :controller do

  let(:all_cases)         { create_list(:case, 5)   }
  let(:first_case)        { all_cases.first         }
  let(:manager)           { create :manager }
  let(:responder)         { create :responder }
  let(:another_responder) { create :responder }
  let(:responding_team)   { create :responding_team,
                                   responders: [responder] }
  let(:assigned_case)     { create :assigned_case,
                                   responding_team: responding_team }
  let(:accepted_case)     { create :accepted_case,
                                   responding_team: responding_team,
                                   responder: responder }
  let(:responded_case)    { create :responded_case,
                                   responding_team: responding_team,
                                   responder: responder }

  before { create(:category, :foi) }

  context "as an anonymous user" do
    describe 'GET index' do
      it "be redirected to signin if trying to list of questions" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'GET new' do
      it "be redirected to signin if trying to start a new case" do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'GET edit' do
      it "be redirected to signin if trying to show a specific case" do
        get :edit, params: { id: first_case }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'PATCH update' do
      it "be redirected to signin if trying to update a specific case" do
        patch :update, params: { id: first_case, case: { category_id: create(:category, :gq).id } }
        expect(response).to redirect_to(new_user_session_path)
        expect(Case.first.category.name).to eq 'Freedom of information request'
      end
    end

    describe 'PATCH close' do
      it "be redirected to signin if trying to close a case" do
        patch :close, params: { id: responded_case }
        expect(response).to redirect_to(new_user_session_path)
        expect(Case.first.current_state).to eq 'responded'
      end
    end

    describe 'GET search' do
      it "be redirected to signin if trying to search for a specific case" do
        name = first_case.name
        get :search, params: { search: name }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context "as an authenticated manager" do

    before { sign_in manager }

    describe 'GET index' do

      let(:unordered_cases) do
        [
          create(:case, received_date: Date.parse('17/11/2016'), subject: 'newer request 2', id: 2),
          create(:case, received_date: Date.parse('17/11/2016'), subject: 'newer request 1', id: 1),
          create(:case, received_date: Date.parse('16/11/2016'), subject: 'request 2', id: 3),
          create(:case, received_date: Date.parse('16/11/2016'), subject: 'request 1', id: 4),
          create(:case, received_date: Date.parse('15/11/2016'), subject: 'older request 2', id: 5),
          create(:case, received_date: Date.parse('15/11/2016'), subject: 'older request 1', id: 6)
        ]
      end

      before {
        get :index
      }

      it 'assigns @cases, sorted by external_deadline, then ID' do
        expect(assigns(:cases)).
          to eq unordered_cases.sort_by { |c| [c.external_deadline, c.id] }
      end

      it 'renders the index template' do
        expect(response).to render_template(:index)
      end
    end

    describe 'GET new' do
      before {
        get :new
      }

      it 'renders the new template' do
        expect(response).to render_template(:new)
      end
    end

    describe 'POST create' do
      context 'with valid params' do

        let(:params) do
          {
            case: {
              requester_type: 'member_of_the_public',
              name: 'A. Member of Public',
              postal_address: '102 Petty France',
              email: 'member@public.com',
              subject: 'FOI request from controller spec',
              message: 'FOI about prisons and probation',
              received_date_dd: Time.zone.today.day.to_s,
              received_date_mm: Time.zone.today.month.to_s,
              received_date_yyyy: Time.zone.today.year.to_s
            }
          }
        end

        let(:kase) { Case.first }

        it 'makes a DB entry' do
          expect { post :create, params: params }.
            to change { Case.count }.by 1
        end

        describe 'using the information supplied  ' do
          before { post :create, params: params }

          it 'for #requester_type' do
            expect(kase.requester_type).to eq 'member_of_the_public'
          end

          it 'for #name' do
            expect(kase.name).to eq 'A. Member of Public'
          end

          it 'for #postal_address' do
            expect(kase.postal_address).to eq '102 Petty France'
          end

          it 'for #email' do
            expect(kase.email).to eq 'member@public.com'
          end

          it 'for #subject' do
            expect(kase.subject).
              to eq 'FOI request from controller spec'
          end

          it 'for #message' do
            expect(kase.message).
              to eq 'FOI about prisons and probation'
          end

          it 'for #received_date' do
            expect(kase.received_date).to eq Time.zone.today
          end
        end
      end
    end

    describe 'GET edit' do

      before do
        get :edit, params: { id: first_case }
      end

      it 'assigns @case' do
        expect(assigns(:case)).to eq(Case.first)
      end

      it 'renders the edit template' do
        expect(response).to render_template(:edit)
      end
    end

    describe 'PATCH update' do

      it 'updates the case record' do
        patch :update, params: {
          id: first_case,
          case: { category_id: create(:category, :gq).id }
        }

        expect(Case.first.category.abbreviation).to eq 'GQ'
      end

      it 'does not overwrite entries with blanks (if the blank dropdown option is selected)' do
        patch :update, params: { id: first_case, case: { category: '' } }
        expect(Case.first.category.abbreviation).to eq 'FOI'
      end
    end

    describe 'GET close' do
      it 'displays the process close page' do
        get :close, params: { id: responded_case }
        expect(response).to render_template(:close)
      end
    end


    describe 'PATCH process_closure' do
      let(:outcome) { create :outcome, :requires_refusal_reason }
      let(:refusal_reason) { create :refusal_reason }

      it "closes a case that has been responded to" do
        patch :process_closure, params: case_closure_params(responded_case)
        expect(Case.first.current_state).to eq 'closed'
        expect(Case.first.outcome_id).to eq outcome.id
        expect(Case.first.date_responded).to eq 3.days.ago.to_date
        expect(Case.first.refusal_reason_id).to eq refusal_reason.id
      end

      def case_closure_params(kase)
        date_responded = 3.days.ago
        {
          id: kase.id,
          case: {
            date_responded_dd: date_responded.day,
            date_responded_mm: date_responded.month,
            date_responded_yyyy: date_responded.year,
            outcome_name: outcome.name,
            refusal_reason_name: refusal_reason.name,
          }
        }
      end
    end

    describe 'GET search' do

      before do
        get :search, params: { search: first_case.name }
      end

      it 'renders the index template' do
        expect(response).to render_template(:index)
      end
    end
  end

  context 'as an authenticated responder' do
    before { sign_in responder }

    describe 'GET index' do
      let(:case1) { create :accepted_case,
                           received_date: Date.parse('17/11/2016'),
                           subject: 'newer request 1',
                           responder: responder }
      let(:case2) { create :accepted_case,
                           received_date: Date.parse('17/11/2016'),
                           subject: 'newer request 2',
                           responder: responder }
      let(:case3) { create :accepted_case,
                           received_date: Date.parse('16/11/2016'),
                           subject: 'request 2',
                           responder: responder }
      let(:case4) { create :accepted_case,
                           received_date: Date.parse('16/11/2016'),
                           subject: 'request 1',
                           responder: responder }
      let(:case5) { create :accepted_case,
                           received_date: Date.parse('15/11/2016'),
                           subject: 'older request 2',
                           responder: responder }
      let(:case6) { create :accepted_case,
                           received_date: Date.parse('15/11/2016'),
                           subject: 'older request 1',
                           responder: responder }
      let(:unordered_cases) do
        [ case2, case1, case4, case3, case6, case5 ]
      end

      let(:responders_workbasket) do
        Case.all.select {|kase| kase.responder == responder}
      end

      before {
        unordered_cases
        responders_workbasket
        get :index
      }

      it 'assigns @cases, sorted by external_deadline, then ID' do
        expect(assigns(:cases)).
          to eq responders_workbasket.sort_by { |c| [c.external_deadline, c.id] }
      end

      it 'renders the index template' do
        expect(response).to render_template(:index)
      end
    end

    describe 'GET new' do
      before {
        get :new
      }

      it 'does not render the new template' do
        expect(response).not_to render_template(:new)
      end

      it 'redirects to the application root path' do
        expect(response).to redirect_to(authenticated_root_path)
      end
    end

    describe 'POST create' do
      let(:kase) { build(:case, subject: 'Responders cannot create cases') }

      let(:params) do
        {
          case: {
            requester_type: 'member_of_the_public',
            name: 'A. Member of Public',
            postal_address: '102 Petty France',
            email: 'member@public.com',
            subject: 'Responders cannot create cases',
            message: 'I am a responder attempting to create a case',
            received_date_dd: Time.zone.today.day.to_s,
            received_date_mm: Time.zone.today.month.to_s,
            received_date_yyyy: Time.zone.today.year.to_s
          }
        }
      end

      subject { post :create, params: params }

      it 'does not create a new case' do
        expect{ subject }.not_to change { Case.count }
      end

      it 'redirects to the application root path' do
        expect(subject).to redirect_to(authenticated_root_path)
      end

      describe 'PATCH close' do
        it "does not close a case that has been responded to" do
          patch :close, params: { id: responded_case }
          expect(Case.first.current_state).not_to eq 'closed'
        end

        it 'redirects to the application root path' do
          expect(subject).to redirect_to(authenticated_root_path)
        end
      end
    end
  end

  # An astute reader who has persevered to this point in the file may notice
  # that the following tests are in a different structure than those above:
  # there, the top-most grouping is a context describing authentication, with
  # what action is being tested (GET new, POST create, etc) sub-grouped within
  # those contexts. This breaks up the tests for, say, GET new so that to read
  # how that action/functionality behaves becomes hard. The tests below seek to
  # remedy this by modelling how they could be grouped by functionality
  # primarily, with sub-grouping for different contexts.

  describe 'GET show' do

    context 'viewing an unassigned case' do
      let(:unassigned_case)       { create(:case) }
      before do
        sign_in user
        get :show, params: { id: unassigned_case.id }
      end

      context 'as an anonymous user' do
        let(:user) { '' }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end

      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it 'permitted_events == [:assign_responder]' do
          expect(assigns(:permitted_events)).to eq [:assign_responder]
        end

        it 'renders the show template' do
          expect(response).to render_template(:show)
        end

      end

      context 'as a responder' do
        let(:user) { create(:responder) }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it 'redirects to the application root path' do
          expect(response).to redirect_to(authenticated_root_path)
        end
      end
    end

    context 'viewing an assigned_case' do
      before do
        sign_in user
        get :show, params: { id: assigned_case.id }
      end

      context 'as an anonymous user' do
        let(:user) { '' }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to eq []
        end

        it 'renders the show template' do
          expect(response).to render_template(:show)
        end
      end

      context 'as a responder of the assigned responding team' do
        let(:user) { responder }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to be_nil
        end

        it 'renders the show template' do
          expect(response)
              .to redirect_to(edit_case_assignment_path(
                                assigned_case,
                                assigned_case.assignments.last.id))
        end
      end

      context 'as a responder of another responding team' do
        let(:user) { another_responder }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it 'redirects to the application root path' do
          expect(response).to redirect_to(authenticated_root_path)
        end
      end
    end

    context 'viewing a case in drafting' do
      let(:accepted_case) { create(:accepted_case)   }
      before do
        sign_in user
        get :show, params: { id: accepted_case.id   }
      end

      context 'as an anonymous user' do
        let(:user) { '' }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to eq []
        end

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as the assigned responder' do
        let(:user) { accepted_case.responder }

        it 'permitted_events == [:add_responses]' do
          expect(assigns(:permitted_events)).to eq [:add_responses]
        end

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as another responder' do
        let(:user) { create(:responder) }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to be_nil
        end

        it 'redirects to the application root path' do
          expect(response).to redirect_to(authenticated_root_path)
        end
      end
    end

    context 'viewing a case_with_response' do
      let(:case_with_response)    { create(:case_with_response) }
      before do
        sign_in user
        get :show, params: { id: case_with_response.id }
      end

      context 'as an anonymous user' do
        let(:user) { '' }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to eq []
        end

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as the assigned responder' do
        let(:user) { case_with_response.responder }

        it 'permitted_events == [:add_responses, :respond]' do
          expect(assigns(:permitted_events)).to eq [:add_responses, :respond]
        end

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as another responder' do
        let(:user) { create(:responder) }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to be_nil
        end

        it 'redirects to the application root path' do
          expect(response).to redirect_to(authenticated_root_path)
        end
      end
    end

    context 'viewing a responded_case' do
      let(:responded_case) { create(:responded_case)   }
      before do
        sign_in user
        get :show, params: { id: responded_case.id   }
      end

      context 'as an anonymous user' do
        let(:user) { '' }

        it 'permitted_events == nil' do
          expect(assigns(:permitted_events)).to eq nil
        end

        it "redirects to signin" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as an authenticated manager' do
        let(:user) { create(:manager) }

        it 'permitted_events == [:close]' do
          expect(assigns(:permitted_events)).to eq [:close]
        end

        it 'renders the show page' do
          expect(response).to have_rendered(:show)
        end
      end

      context 'as the previously assigned responder' do
        let(:user) { responder }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to be_nil
        end

        it 'redirects to the application root path' do
          expect(response).to redirect_to(authenticated_root_path)
        end
      end

      context 'as another responder' do
        let(:user) { create(:responder) }

        it 'permitted_events == []' do
          expect(assigns(:permitted_events)).to be_nil
        end

        it 'redirects to the application root path' do
          expect(response).to redirect_to(authenticated_root_path)
        end
      end
    end
  end

  describe 'GET new_response_upload' do
    let(:kase) { create(:accepted_case, responder: responder) }

    context 'as an anonymous user' do
      describe 'GET new_response_upload' do
        it 'redirects to signin' do
          get :new_response_upload, params: { id: kase }
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context "as a responder who isn't assigned to the case" do
      let(:unassigned_responder) { create(:responder) }

      before { sign_in unassigned_responder }

      it 'redirects to case detail page' do
        get :new_response_upload, params: { id: kase }
        expect(response).to redirect_to(case_path(kase))
      end
    end

    shared_examples 'signed-in user can view attachment upload page' do
      it 'assigns @case' do
        get :new_response_upload, params: { id: kase }
        expect(assigns(:case)).to eq(Case.first)
      end

      it 'renders the new_response_upload view' do
        get :new_response_upload, params: { id: kase }
        expect(response).to have_rendered(:new_response_upload)
      end
    end

    context 'as the assigned responder' do
      before { sign_in responder }

      it_behaves_like 'signed-in user can view attachment upload page'
    end

    context 'as an authenticated manager' do
      before { sign_in manager }

      it 'redirects to case detail page' do
        get :new_response_upload, params: { id: kase }
        expect(response).to redirect_to(case_path(kase))
      end
    end

  end

  describe 'POST upload_responses' do
    let(:kase) { create(:accepted_case, responder: responder) }
    let(:uploads_key) do
      "uploads/#{kase.id}/responses/#{Faker::Internet.slug}.jpg"
    end
    let(:destination_key) { uploads_key.sub(%r{^uploads/}, '') }
    let(:destination_path) do
      "correspondence-staff-case-uploads-testing/#{destination_key}"
    end
    let(:uploads_object) { instance_double(Aws::S3::Object, 'uploads_object') }
    let(:public_url) do
      "#{CASE_UPLOADS_S3_BUCKET.url}/#{URI.encode(destination_key)}"
    end
    let(:destination_object) do
      instance_double Aws::S3::Object, 'destination_object',
                      public_url: public_url
    end
    let(:leftover_files) { [] }

    before do
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                         .with(uploads_key)
                                         .and_return(uploads_object)
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                         .with(destination_key)
                                         .and_return(destination_object)
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:objects)
                                         .with(prefix: "uploads/#{kase.id}")
                                         .and_return(leftover_files)
      allow(uploads_object).to receive(:move_to).with(
                                 destination_path
                               )
    end

    def do_upload_responses
      post :upload_responses, params: {
             id:             kase,
             type:           'response',
             uploaded_files: [uploads_key]
           }
    end

    context 'as an anonymous user' do
      it "doesn't add the attachment" do
        expect do
          do_upload_responses
        end.not_to change { kase.attachments.count }
      end

      it 'redirects to signin' do
        do_upload_responses
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as a responder who isn't assigned to the case" do
      let(:unassigned_responder) { create(:responder) }

      before { sign_in unassigned_responder }

      it "doesn't add the attachment" do
        expect do
          do_upload_responses
        end.not_to change { kase.attachments.count }
      end

      it 'redirects to case detail page' do
        do_upload_responses
        expect(response).to redirect_to(case_path(kase))
      end
    end

    context 'as the assigned responder' do
      before { sign_in responder }

      it 'creates a new case attachment' do
        expect { do_upload_responses }.
          to change { kase.reload.attachments.count }
      end

      it 'moves the file out of the uploads dir' do
        do_upload_responses
        expect(uploads_object).to have_received(:move_to).with(
                                    destination_path
                                  )
      end

      it 'test the type field' do
        do_upload_responses
        expect(kase.attachments.first.type).to eq 'response'
      end

      it 'redirects to the case detail page' do
        do_upload_responses
        expect(response).to redirect_to(case_path(kase))
      end

      context 'files removed from dropzone upload' do
        let(:leftover_files) do
          [instance_double(Aws::S3::Object, delete: nil)]
        end

        it 'removes any files left behind in uploads' do
          do_upload_responses
          leftover_files.each do |object|
            expect(object).to have_received(:delete)
          end
        end
      end

      context 'an attachment already exists with the same name' do
        let(:attachment) do
          create :case_response,
                 key: destination_key,
                 case: kase
        end

        before do
          attachment
        end

        it 'does not create a new case_attachment object' do
          expect { do_upload_responses }.
            not_to change { kase.reload.attachments.count }
        end

        it 'updates the updated_at time of the existing attachment' do
          expect { do_upload_responses }.
            to change { kase.reload.attachments.first.updated_at }
        end

        it 'updates the existing attachment' do
          do_upload_responses
          expect(uploads_object).to have_received(:move_to).with(
                                      destination_path
                                    )
        end
      end

      context 'uploading invalid attachment type' do
        let(:uploads_key) do
          "uploads/#{kase.id}/responses/invalid.exe"
        end

        it 'renders the new_response_upload page' do
          do_upload_responses
          expect(response).to have_rendered(:new_response_upload)
        end

        it 'does not create a new case attachment' do
          expect { do_upload_responses }.
            to_not change { kase.reload.attachments.count }
        end

        xit 'removes the attachment from S3'
      end

      context 'uploading attachment that are too large' do
        xit 'renders the new_response_upload page' do
          do_upload_responses
          expect(response).to have_rendered(:new_response_upload)
        end

        xit 'does not create a new case attachment' do
          expect { do_upload_responses }.
            to_not change { kase.reload.attachments.count }
        end

        xit 'removes the attachment from S3'
      end

      context 'does not upload any valid files' do

        it 'Returns error message if not files uploaded' do
          post :upload_responses, params: {
              id:             kase,
              type:           'response'
          }
          expect(flash[:alert]).to eq 'Please select the file(s) you used in your response.'
          expect(response).to have_rendered(:new_response_upload)


        end

      end
    end

    context 'as a manager' do
      before { sign_in manager }

      it 'redirects to case detail page' do
        get :new_response_upload, params: { id: kase }
        expect(response).to redirect_to(case_path(kase))
      end
    end
  end

  describe 'GET respond' do

    let(:responder)            { create(:responder)                              }
    let(:another_responder)    { create(:responder)                              }
    let(:case_with_response) { create(:case_with_response, responder: responder) }

    context 'as an anonymous user' do
      it 'redirects to sign_in' do
        expect(get :respond, params: { id: case_with_response.id }).
          to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated manager' do

      before { sign_in manager }

      it 'redirects to the application root' do
        expect(get :respond, params: { id: case_with_response.id }).
            to redirect_to(authenticated_root_path)
      end
    end

    context 'as the assigned responder' do

      before { sign_in responder }

      it 'does not transition current_state' do
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
        get :respond, params: { id: case_with_response.id }
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
      end

      it 'renders the respond template' do
        expect(get :respond, params: { id: case_with_response.id }).
            to render_template(:respond)
      end
    end

    context 'as another responder' do

      before { sign_in another_responder }

      it 'redirects to the application root' do
        expect(get :respond, params: { id: case_with_response.id }).
              to redirect_to(authenticated_root_path)
      end
    end
  end

  describe 'PATCH confirm_respond' do

    let(:responder)            { create(:responder)                              }
    let(:another_responder)    { create(:responder)                              }
    let(:case_with_response) { create(:case_with_response, responder: responder) }

    context 'as an anonymous user' do
      it 'redirects to sign_in' do
        expect(patch :confirm_respond, params: { id: case_with_response.id }).
          to redirect_to(new_user_session_path)
      end

      it 'does not transition current_state' do
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
        patch :confirm_respond, params: { id: case_with_response.id }
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
      end
    end

    context 'as an authenticated manager' do

      before { sign_in manager }

      it 'redirects to the application root' do
        expect(patch :confirm_respond, params: { id: case_with_response.id }).
            to redirect_to(authenticated_root_path)
      end

      it 'does not transition current_state' do
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
        patch :confirm_respond, params: { id: case_with_response.id }
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
      end
    end

    context 'as the assigned responder' do

      before { sign_in responder }

      it 'transitions current_state to "responded"' do
        patch :confirm_respond, params: { id: case_with_response }
        expect(case_with_response.current_state).to eq 'responded'
        expect(case_with_response.transitions.last.assignee_id).to eq responder.id
      end

      it 'updates assignee id in transition' do
        patch :confirm_respond, params: { id: case_with_response }
        expect(case_with_response.transitions.last.assignee_id).to eq responder.id
      end

      it 'updates user id in transition' do
        patch :confirm_respond, params: { id: case_with_response }
        expect(case_with_response.transitions.last.user_id).to eq responder.id
      end

      it 'removes the case from the responders workbasket' do
        patch :confirm_respond, params: { id: case_with_response }
        workbasket = CasePolicy::Scope.new(responder, Case.all).resolve
        expect(workbasket).not_to include case_with_response
      end

      it 'redirects to the case list view' do
        expect(patch :confirm_respond, params: { id: case_with_response.id }).
            to redirect_to(cases_path)
      end
    end

    context 'as another responder' do

      before { sign_in another_responder }

      it 'redirects to the application root' do
        expect(patch :confirm_respond, params: { id: case_with_response.id }).
              to redirect_to(authenticated_root_path)
      end

      it 'does not transition current_state' do
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
        patch :confirm_respond, params: { id: case_with_response.id }
        expect(case_with_response.current_state).to eq 'awaiting_dispatch'
      end
    end
  end
end
