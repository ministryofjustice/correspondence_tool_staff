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
        expect(contact_type.errors.attribute_names).to include :contact_type_id
        expect(contact_type.errors.full_messages).to eq ["Select the contact type of the new address "]
      end
    end
  end
end
