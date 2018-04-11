class AddDocumentTsvectorToCases < ActiveRecord::Migration[5.0]
  def up
    execute 'ALTER TABLE cases ADD COLUMN document_tsvector tsvector;'
    execute 'CREATE INDEX cases_document_tsvector_index ON cases USING GIN (document_tsvector);'
  end

  def down
    execute 'DROP INDEX cases_document_tsvector_index;'
    execute 'ALTER TABLE cases DROP COLUMN document_tsvector;'
  end
end
