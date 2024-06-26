require "rails_helper"

RSpec.shared_examples "new overturned ico spec" do |klass|
  it "authorizes" do
    expect { get :new, params: { id: kase.id } }
      .to require_permission(:new?)
        .with_args(manager, klass)
  end

  context "when post-authorization processing" do
    let(:service) { instance_double NewOverturnedICOCaseService }

    before do
      allow(NewOverturnedICOCaseService)
        .to receive(:new).with(kase.id.to_s).and_return(service)
      allow(service).to receive(:call)
      allow(service).to receive(:original_ico_appeal).and_return(kase)
    end

    context "with valid params" do
      let(:decorated_overturned_ico) do
        class_double(
          decorator,
          type_abbreviation: abbreviation,
        )
      end

      let(:overturned_ico) do
        class_double(
          klass,
          decorate: decorated_overturned_ico,
        )
      end

      before do
        allow(service).to receive(:error?).and_return(false)
        allow(service).to receive(:overturned_ico_case).and_return(overturned_ico)
        get :new, params: { id: kase.id }
      end

      it "assigns @case from the case creation service" do
        expect(assigns(:case)).to eq decorated_overturned_ico
      end

      it "assigns the original_ico_appeal from the case creation service" do
        expect(assigns(:original_ico_appeal)).to eq kase
      end

      it "renders the new template" do
        expect(response).to render_template("cases/#{abbreviation.downcase}/new")
      end

      it "has a status of success" do
        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid params" do
      let(:decorated_ico_appeal) { class_double ico_decorator }

      before do
        allow(service).to receive(:error?).and_return(true)
        allow(kase).to receive(:decorate).and_return(decorated_ico_appeal)
        get :new, params: { id: kase.id }
      end

      it "assigns @case from the service original ico appeal" do
        expect(assigns(:case)).to eq decorated_ico_appeal
      end

      it "renders the show page" do
        expect(response).to render_template(:show)
      end

      it "has a status of bad request" do
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
