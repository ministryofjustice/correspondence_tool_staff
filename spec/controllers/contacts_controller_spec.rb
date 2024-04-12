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
      let(:errors) { assigns(:case).errors.messages }
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
        expect(contact_type.errors[:contact_type_id]).to eq ["can't be blank"]
      end
    end
  end

  describe "#update" do
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

    it "cannot update the contact_type" do
      debugger
      patch(:new_details, params:)
      contacts = assigns(:contacts)
      debugger
    end
  end
end
