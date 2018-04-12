module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch

    self.ignored_columns = self.ignored_columns + [searchable_document_tsvector]

    pg_search_scope :search,
                    against: searchable_fields_and_ranks,
                    using: { tsearch: {
                               any_word: true,
                               dictionary: 'english',
                               tsvector_column: searchable_document_tsvector,
                             }
                           }
  end

  class_methods do
    def update_all_indexes
      self.all.each(&:update_index)
    end
  end

  def update_index
    tsvector = self.class.searchable_fields_and_ranks.map do |field_name, rank|
      field_data = self.class.connection.quote __send__(field_name) || ''
      "setweight(to_tsvector('english', '#{field_data}'), '#{rank}')"
    end .join(' || ')
    update_sql = <<~EOSQL
      UPDATE #{self.class.table_name}
             SET document_tsvector=#{tsvector}
             WHERE id=#{id};
    EOSQL
    self.class.connection.execute update_sql
  end


end
