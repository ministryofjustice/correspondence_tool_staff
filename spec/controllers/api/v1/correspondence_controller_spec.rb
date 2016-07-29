require 'rails_helper'

RSpec.describe Api::V1::CorrespondenceController, type: :controller do

  let(:params) do
    {
      name: Faker::Name.name,
      email: 'email@example.com',
      email_confirmation: 'email@example.com',
      category: 'freedom_of_information_request',
      topic: 'prisons',
      message: Faker::Lorem.paragraph(1)
    }
  end

  before { request.headers["HTTP_AUTHORIZATION"] = "Token token=\"#{ENV['WEB_FORM_AUTH_TOKEN']}\"" }

  context 'when authentication succeeds' do

    describe 'POST #create' do

      context 'with valid params' do

        before { post :create, params: { correspondence: params } }

        it 'creates a new item of correspondence' do
          expect(Correspondence.count).to eq 1
        end

        it 'returns status 201/created' do
          expect(response.status).to eq 201
        end

        it 'returns the id of the new DB entry' do
          expect(response.body).to eq Correspondence.first.id.to_s
        end

      end

      context 'with invalid params' do

        before do
          params.delete(:name)
          post :create, params: { correspondence: params }
        end

        it 'does not create a new item of correspondence' do
          expect(Correspondence.count).to eq 0
        end

        it 'returns status 422/unprocessable entity' do
          expect(response.status).to eq 422
        end

        it 'returns a list of errors' do
          expect(JSON.parse(response.body)).to eq(
            'errors' => { 'name' => ['can\'t be blank'] }
          )
        end

      end

    end

  end

  context 'when authenticaion fails' do

    before {
      request.headers["HTTP_AUTHORIZATION"] = "Token token=\"INVALID_TOKEN\""
      post :create, params: { correspondence: params }
    }

    it 'returns an explanatory json message' do
      expect(response.status).to eq 401
    end

  end

end
