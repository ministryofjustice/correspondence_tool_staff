module Searchable
  extend ActiveSupport::Concern

  include SearchHelper
  
  included do
    include PgSearch::Model

    self.ignored_columns = self.ignored_columns + [searchable_document_tsvector]

    SearchHelper::SEARCH_SCOPE_SET.keys().each do | scope_key |
      pg_search_scope scope_key,
                      against: searchable_fields_and_ranks,
                      order_within_rank: SearchHelper::SEARCH_SCOPE_SET[scope_key]["order"],
                      using: { tsearch: {
                                any_word: false,
                                dictionary: 'english',
                                tsvector_column: searchable_document_tsvector,
                                prefix: true,
                              }
                            }
    end

  end

  class_methods do
    def update_all_indexes
      self.all.find_each(&:update_index)
    end
  end

  def update_index
    tsvector = self.class.searchable_fields_and_ranks.map do |field_name, rank|
      field_data = self.class.connection.quote __send__(field_name) || ''
      "setweight(to_tsvector('english', #{field_data}), '#{rank}')"
    end .join(' || ')
    update_sql = <<~EOSQL
      UPDATE #{self.class.table_name}
             SET document_tsvector=#{tsvector}
             WHERE id=#{id};
    EOSQL
    self.class.connection.execute update_sql
  end


end
