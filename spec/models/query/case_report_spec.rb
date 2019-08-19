require 'rails_helper'

RSpec.describe Query::CaseReport do
  before do
    ::Warehouse::CaseReport.generate(create :sar_case)
    ::Warehouse::CaseReport.generate(create :foi_case)
    ::Warehouse::CaseReport.generate(create :closed_case)
  end

  let(:default_retrieval_scope) { Case::Base.all }

  describe '#initialize' do
    it 'has default attributes' do
      query = described_class.new(retrieval_scope: default_retrieval_scope)
      expect(query.columns).to eq ['*']
      expect(query.offset).to be_nil
      expect(query.limit).to be_nil
    end

    it 'accepts an array of field names to select from CaseReport' do
      fields = ['name', 'useless_field', 'lol']
      query = described_class.new(
        retrieval_scope: default_retrieval_scope,
        columns: fields
      )
      expect(query.columns).to eq fields

      expect {
        described_class.new(
          retrieval_scope: default_retrieval_scope,
          columns: 'name, useless_field, lol'
        ).query
      }.to raise_error NoMethodError

    end

    it 'uses given retrieval_scope parameter' do
      sql_query = described_class.new(
        retrieval_scope: Case::SAR::Standard.all
      ).query

      result = ActiveRecord::Base.connection.execute(sql_query)
      expect(result.count).to eq 1
      expect(result.all? { |kase| kase['case_type'] == 'SAR' }).to be true
    end

    it 'uses given columns parameter' do
      sql_query = described_class.new(
        retrieval_scope: Case::FOI::Standard.all,
        columns: ['email'],
      ).query

      result = ActiveRecord::Base.connection.execute(sql_query)
      expect(result.count).to eq 2
      expect(result.all? { |kase| kase.keys == ['email'] }).to be true
    end

    it 'uses given offset parameter' do
      sql_query = described_class.new(
        retrieval_scope: Case::Base.all,
        offset: 1,
      ).query

      result = ActiveRecord::Base.connection.execute(sql_query)
      expect(result.count).to eq 2
    end

    it 'uses given limit parameter' do
      sql_query = described_class.new(
        retrieval_scope: Case::Base.all,
        limit: 2,
      ).query

      result = ActiveRecord::Base.connection.execute(sql_query)
      expect(result.count).to eq 2
    end
  end
end
