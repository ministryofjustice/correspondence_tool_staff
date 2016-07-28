require 'rails_helper'


RSpec.describe Api::V1::CorrespondenceController, type: :controller do

  context 'when authentication succeeds' do

    describe 'POST #create' do

      let(:params) do
        {
          name: Faker::Name.name,
          email: 'email@example.com',
          email_confirmation: 'email@example.com',
          typus: 'freedom_of_information_request',
          topic: 'prisons',
          message: Faker::Lorem.paragraph(1)
        }
      end

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

        before { params.delete(:name); post :create, params: { correspondence: params } }

        it 'does not create a new item of correspondence' do
          expect(Correspondence.count).to eq 0
        end

        it 'returns status 422/unprocessable entity' do
          expect(response.status).to eq 422
        end

        it 'returns a list of errors' do
          expect(JSON.parse(response.body)).to eq(
            { 'errors' => { 'name' => ['can\'t be blank'] } }
          ) 
        end

      end

    end

  end

end
