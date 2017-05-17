require 'rails_helper'



describe GlobalNavManager::GlobalNavManagerEntry do

  context 'initialized with an array of urls' do
    let(:entry) { GlobalNavManager::GlobalNavManagerEntry.new('Cases', ['cases_path', 'root_path', 'other_path']) }

    describe '#text' do
      it 'returns the text' do
        expect(entry.text).to eq 'Cases'
      end
    end

    describe '#urls' do
      it 'returns an array of urls' do
        expect(entry.urls).to eq ['cases_path', 'root_path', 'other_path']
      end
    end

    describe '#url' do
      it 'returns the first url' do
        expect(entry.url).to eq 'cases_path'
      end
    end
  end

  context 'intialized with just one url' do
    let(:entry) { GlobalNavManager::GlobalNavManagerEntry.new('Cases', 'cases_path') }

    describe '#text' do
      it 'returns the text' do
        expect(entry.text).to eq 'Cases'
      end
    end

    describe '#urls' do
      it 'returns an array of one url' do
        expect(entry.urls).to eq ['cases_path']
      end
    end

    describe '#url' do
      it 'returns the  url' do
        expect(entry.url).to eq 'cases_path'
      end
    end
  end
end


describe GlobalNavManager do
  include Rails.application.routes.url_helpers

  # we need to add in equality matcher for GlobalNavManagerEntry here just for testing
  class GlobalNavManager::GlobalNavManagerEntry
    def ==(other)
      @text == other.text && @urls == other.urls
    end
  end

  let(:incoming_cases_entry) do
    GlobalNavManager::GlobalNavManagerEntry.new 'Incoming cases',
                                                incoming_cases_path
  end
  let(:open_cases_entry) do
    GlobalNavManager::GlobalNavManagerEntry.new 'Open cases',
                                                [open_cases_path]
  end
  let(:my_open_cases_entry) do
    GlobalNavManager::GlobalNavManagerEntry.new 'My open cases',
                                                [my_open_cases_path]
  end
  let(:closed_cases_entry) do
    GlobalNavManager::GlobalNavManagerEntry.new 'Closed cases',
                                                closed_cases_path
  end

  context 'manager user' do
    let(:user) { create :manager }
    let(:gnm)  { GlobalNavManager.new(user) }

    describe '#each' do
      it 'yields for every entry in the Nav Bar' do
        expect { |block| gnm.each(&block) }
          .to yield_successive_args(open_cases_entry, closed_cases_entry)
      end
    end
  end

  context 'responder user' do
    let(:user) { create :responder }
    let(:gnm)  { GlobalNavManager.new(user) }

    describe '#each' do
      it 'yields for every entry in the Nav Bar' do
        expect { |block| gnm.each(&block) }
          .to yield_successive_args(open_cases_entry, closed_cases_entry)
      end
    end
  end

  context 'approver user' do
    let(:user) { create :approver }
    let(:gnm)  { GlobalNavManager.new(user) }

    describe '#each' do
      it 'yields for every entry in the Nav Bar' do
        expect { |block| gnm.each(&block) }
          .to yield_successive_args incoming_cases_entry,
                                    open_cases_entry,
                                    my_open_cases_entry,
                                    closed_cases_entry
      end
    end
  end
end
