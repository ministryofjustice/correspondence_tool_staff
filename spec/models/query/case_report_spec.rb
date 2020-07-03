require 'rails_helper'

RSpec.describe Query::CaseReport do
  let(:sar_case) { create :sar_case }
  let(:foi_case) { create :foi_case }
  let(:closed_case) { create :closed_case }

  before do
    ::Warehouse::CaseReport.generate(sar_case)
    ::Warehouse::CaseReport.generate(foi_case)
    ::Warehouse::CaseReport.generate(closed_case)
  end

  let(:default_retrieval_scope) { Case::Base.all }
  let(:external_deadline_retrieval_scope) { 
    Case::Base.all.select(:id).order(Arel.sql("(properties ->> 'external_deadline')::timestamp with time zone")) 
  }

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

    it 'uses given limit parameter with offset' do
      sql_query = described_class.new(
        retrieval_scope: external_deadline_retrieval_scope,
        limit: 2,
        offset: 0,
      ).query
      
      result_set = Set.new
      expected_result = Set.new

      result = ActiveRecord::Base.connection.execute(sql_query)
      expect(result.count).to eq 2
      result_set << result[0]['id']
      result_set << result[1]['id']

      expected_result << foi_case['id']
      expected_result << closed_case['id']

      expect(result_set).to eq expected_result

      sql_query = described_class.new(
        retrieval_scope: external_deadline_retrieval_scope,
        limit: 1,
        offset: 2,
      ).query

      result = ActiveRecord::Base.connection.execute(sql_query)
      expect(result.count).to eq 1
      expect(result[0]['id']).to eq sar_case['id']
    end
  end
end
