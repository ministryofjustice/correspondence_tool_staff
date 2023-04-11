require 'rails_helper'

describe DataRequestDecorator, type: :model do
  describe '#request_dates' do
    let(:decorated) { find_or_create(:data_request).decorate }

    context 'only a from date' do
      let(:decorated) { find_or_create(:data_request, date_from: Date.new(2022, 8, 20)).decorate }

      it 'returns expected string' do
        expect(decorated.request_dates).to eq 'from 20/08/2022 to date'
      end
    end

    context 'only a to date' do
      let(:decorated) { find_or_create(:data_request, date_to: Date.new(2022, 12, 13)).decorate }

      it 'returns expected string' do
        expect(decorated.request_dates).to eq 'up to 13/12/2022'
      end
    end

    context 'both from and to dates' do
      let(:decorated) { find_or_create(:data_request, date_from: Date.new(2022, 12, 13), date_to: Date.new(2022, 12, 13)).decorate }

      it 'returns expected string' do
        expect(decorated.request_dates).to eq 'from 13/12/2022 to 13/12/2022'
      end
    end

    context 'neither to or from dates' do
      it 'returns an empty string' do
        expect(decorated.request_dates).to eq ''
      end
    end
  end

  describe '#location' do
    let(:data_request) { create(:data_request) }

    context 'without linked organisation' do
      let(:decorated) { data_request.decorate }

      it 'uses location string' do
        expect(decorated.location).to eq data_request.location
      end
    end

    context 'with linked organisation' do
      let(:contact) { create(:contact) }
      let(:decorated) { data_request.decorate }

      before do
        data_request.update_attribute(:contact, contact)
      end

      it 'uses name of organisation' do
        expect(decorated.location).to eq contact.name
      end
    end
  end

  describe '#data_request_name' do
    let(:data_request) { create(:data_request) }

    context 'without linked organisation' do
      let(:decorated) { data_request.decorate }

      it 'uses location string' do
        expect(decorated.data_request_name).to eq data_request.location
      end
    end

    context 'with linked organisation' do
      let(:contact) { create(:contact) }
      let(:decorated) { data_request.decorate }
      let(:example_name) { 'Jim Smith Brixton Prison'}

      before do
        data_request.update_attribute(:contact, contact)
      end

      context 'contact has data_request_name' do
        it 'uses data_request_name of organisation' do
          contact.update_attribute(:data_request_name, example_name)
          expect(decorated.data_request_name).to eq example_name
        end
      end

      context 'contact does not have data_request_name' do
        it 'uses name of organisation' do
          expect(decorated.data_request_name).to eq contact.name
        end
      end
    end
  end

  describe '#data_required' do
    context 'when request_type = other' do
      let(:data_request) { create(:data_request, request_type: 'other', request_type_note: 'some information') }
      let(:decorated) { data_request.decorate }

      it 'uses location string' do
        expect(decorated.data_required).to eq data_request.request_type_note
      end
    end

    context 'when request_type != other' do
      let(:data_request) { create(:data_request) }
      let(:decorated) { data_request.decorate }

      it 'uses location string' do
        expect(decorated.data_required).to be_nil
      end
    end
  end
end
