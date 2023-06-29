require "rails_helper"

# rubocop:disable RSpec/InstanceVariable
RSpec.describe Searchable do
  before do
    @searchable_class = Class.new do
      # Setup this class to emulate how a model would be setup, and how it would
      # use the Searchable concern.

      class << self
        # cannot create doubles otherwise
        include RSpec::Mocks::ExampleMethods

        def table_name
          "searchable"
        end
      end

      # ignored_columns is provided by ActiveRecord so we emulate it here
      def self.ignored_columns
        @ignored_columns ||= [].freeze
      end

      class << self
        attr_writer :ignored_columns
      end

      # standard method that a model would need to define
      def self.searchable_document_tsvector
        @searchable_document_tsvector ||= "searchable_document_tsvector"
      end

      # standard method that a model would need to define
      def self.searchable_fields_and_ranks
        @searchable_fields_and_ranks ||= {
          field_a: "A",
          field_b: "B",
        }
      end

      # pretending to be an ActiveRecord object again, with some doubled
      # objects we can set expectations on in the specs
      def self.all
        @all ||= [
          double("Object A", update_index: true), # rubocop:disable RSpec/VerifiedDoubles
          double("Object B", update_index: true), # rubocop:disable RSpec/VerifiedDoubles
        ]
      end

      include Searchable
    end

    @searchable = @searchable_class.new
  end

  describe "ignored_columns" do
    it "adds the searchable_document_tsvector to it" do
      expect(@searchable_class.ignored_columns.first)
        .to be @searchable_class.searchable_document_tsvector
    end
  end

  describe ".update_all_indexes" do
    it "updates all cases" do
      @searchable.class.update_all_indexes

      expect(@searchable.class.all).to all have_received :update_index
    end
  end

  describe "#update_index" do
    it "updates the document_tsvector column" do
      allow(@searchable).to receive("field_a").and_return("foobar")
      allow(@searchable).to receive("field_b").and_return("barfoo")
      allow(@searchable).to receive("id").and_return(1)
      connection = double("Connection", execute: true) # rubocop:disable RSpec/VerifiedDoubles
      allow(@searchable.class).to receive(:connection).and_return(connection)
      allow(connection).to receive("quote").with(any_args) { |d| "'#{d}'" }

      @searchable.update_index

      update_sql = <<~EOSQL
        UPDATE searchable
               SET document_tsvector=setweight(to_tsvector('english', 'foobar'), 'A') || setweight(to_tsvector('english', 'barfoo'), 'B')
               WHERE id=1;
      EOSQL
      expect(connection).to have_received(:execute).with(update_sql)
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
