module Searchable
  extend ActiveSupport::Concern

  include SearchHelper

  included do
    include PgSearch::Model

    self.ignored_columns = ignored_columns + [searchable_document_tsvector]

    SearchHelper::SEARCH_SCOPE_SET.each_key do |scope_key|
      pg_search_scope scope_key,
                      against: searchable_fields_and_ranks,
                      order_within_rank: SearchHelper::SEARCH_SCOPE_SET[scope_key]["order"],
                      using: { tsearch: {
                        any_word: false,
                        dictionary: "english",
                        tsvector_column: searchable_document_tsvector,
                        prefix: true,
                      } }
    end
  end

  class_methods do
    def update_all_indexes
      Rails.configuration.event_store.publish(
        Events::ReindexStarted.build({ started_at: Time.zone.now }),
        stream_name: "ReindexCases",
      )
      total_reindexed = 0

      Case::Base.in_batches(of: 1000) do |batch|
        vectors = batch.map { |kase| [kase.id, kase.tsvector] }

        update_sql = <<~EOSQL
          UPDATE #{table_name} AS t SET
            document_tsvector = c.document_tsvector,
            last_indexed_at = NOW()
          FROM (VALUES
            #{vectors.map { |id, vector| "(#{id}, #{vector})" }.join(",\n")}
          ) AS c(id, document_tsvector)
          WHERE c.id = t.id;
        EOSQL

        connection.execute(update_sql)
        total_reindexed += batch.size
      end

      Rails.configuration.event_store.publish(
        Events::ReindexCompleted.build({ completed_at: Time.zone.now, total_reindexed: total_reindexed }),
        stream_name: "ReindexCases",
      )
    end
  end

  def update_index
    update_sql = <<~EOSQL
      UPDATE #{self.class.table_name}
      SET document_tsvector=#{tsvector}, last_indexed_at = NOW()
      WHERE id=#{id};
    EOSQL

    self.class.connection.execute(update_sql)
  end

  def tsvector
    self.class.searchable_fields_and_ranks.map { |field_name, rank|
      field_data = self.class.connection.quote __send__(field_name) || ""

      "setweight(to_tsvector('english', #{field_data}), '#{rank}')"
    }.join(" || ")
  end
end
