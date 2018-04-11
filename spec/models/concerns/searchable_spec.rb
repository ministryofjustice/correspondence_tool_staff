require "rails_helper"

RSpec.describe Searchable do
  before :each do

    @searchable = Class.new do
      # Setup this class to emulate how a model would be setup, and how it would
      # use the Searchable concern.

      class << self
        # can't create doubles otherwise
        include RSpec::Mocks::ExampleMethods
      end

      # ignored_columns is provided by ActiveRecord so we emulate it here
      def self.ignored_columns
        @ignored_columns ||= [].freeze
      end

      def self.ignored_columns=(cols)
        @ignored_columns = cols
      end

      # standard method that a model would need to define
      def self.searchable_document_tsvector
        @searchable_document_tsvector ||= 'searchable_document_tsvector'
      end

      # standard method that a model would need to define
      def self.searchable_fields_and_ranks
        @searchable_fields_and_ranks ||= {
          field_a: 'A'
        }
      end

      # pretending to be an ActiveRecord object again, with some doubled
      # objects we can set expectations on in the specs
      def self.all
        @all ||= [
          double('Object A', update_index: true),
          double('Object B', update_index: true),
        ]
      end

      include Searchable
    end
  end

  describe 'ignored_columns' do
    it 'adds the searchable_document_tsvector to it' do
      expect(@searchable.ignored_columns.first)
        .to be @searchable.searchable_document_tsvector
    end
  end

  describe '.update_all_indexes' do
    it 'updates all cases' do
      @searchable.update_all_indexes

      @searchable.all.each { |obj| expect(obj).to have_received :update_index }
    end
  end

  describe '#update_index' do
    it 'indexes the searchable fields'

    it 'sets the weighting on indexed fields'
  end
end
