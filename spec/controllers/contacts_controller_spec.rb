require "rails_helper"

RSpec.describe ContactsController, type: :controller do
  let(:user) { create(:user) }

  let!(:stafford) { create(:contact, name: "stafford") }
  let!(:winsongreen) { create(:contact, name: "winson green") }
  let!(:brinsford) { create(:contact, name: "brinsford") }

  describe "GET #index" do
    before do
      sign_in user
    end

    it "returns an alphabetically sorted list of contacts" do
      # Assuming the controller action assigns @contacts
      get :index

      # Extract the contacts from the controller's instance variable
      contacts = assigns(:contacts)

      # Check if the contacts are sorted alphabetically by their name
      expect(contacts).to eq [brinsford, stafford, winsongreen]
    end
  end

  describe "GET #new" do
    before do
      sign_in user
    end

    it "renders the new page" do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe "#new_details" do
    before do
      sign_in user
    end

    let(:params) do
      {
        contact_type: {
          contact_type_id: 1,
        },
      }
    end

    it "renders the new_details page" do
      get(:new_details, params:)
      expect(response).to render_template(:new_details)
    end

    context "with invalid contact_type_id" do
      let(:params) do
        {
          contact_type: {
            contact_type_id: nil,
          },
        }
      end

      it "raises an error" do
        post(:new_details, params:)
        contact_type = assigns(:contact_type)
        expect(contact_type.errors.attribute_names).to include :contact_type_id
        expect(contact_type.errors.full_messages).to eq ["Select the contact type of the new address "]
      end
    end

    context "when user skips new page and navigates straight to new_details page" do
      it "redirects to new page" do
        get :new_details
        expect(response.body).to redirect_to new_contact_path
      end
    end
  end

  describe "#create" do
    let(:contact_type) { create(:category_reference) }
    let(:params) do
      {
        contact: {
          name: "HMP halifax",
          address_line_1: "123 test road",
          address_line_2: nil,
          town: nil,
          county: nil,
          postcode: "FE2 9JK",
          data_request_emails: nil,
          contact_type_id: contact_type,
        },
      }
    end

    before do
      sign_in user
    end

    it "redirects to the contacts index page" do
      post(:create, params:)
      expect(response).to redirect_to(contacts_path)
    end
  end

  describe "#update" do
    let(:contact_type_2) { create(:category_reference, category: "contact_type_2") }
    let(:params) do
      {
        id: stafford.id,
        contact: {
          name: "New name",
          address_line_1: "new address",
          address_line_2: nil,
          town: nil,
          county: nil,
          postcode: "FE2 9JK",
          data_request_emails: nil,
          contact_type_id: contact_type_2,
        },
      }
    end

    before do
      sign_in user
    end

    it "redirects to the contacts index page" do
      patch(:update, params:)
      expect(response).to redirect_to(contacts_path)
    end

    it "does not update contact_type_id value" do
      expect {
        patch(:update, params:)
      }.not_to(
        change { stafford.reload.contact_type },
      )
    end
  end
end
