class CreateSearchIndex < ActiveRecord::Migration[5.0]
  def up
    sql = <<-EOSQL
      CREATE TABLE "search_index" (
        "id" serial primary key,
        "case_id" integer NOT NULL,
        "document" tsvector NOT NULL
      )
    EOSQL
    execute sql
    execute "CREATE INDEX search_index_idx ON search_index USING GIN (document)"
  end

  def down
    execute "DROP INDEX search_index_idx"
    execute "DROP TABLE search_index"
  end
end

############################ make case id a unique index ####################
