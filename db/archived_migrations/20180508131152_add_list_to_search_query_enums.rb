class AddListToSearchQueryEnums < ActiveRecord::Migration[5.0]

  disable_ddl_transaction!

  def up
    alter_enum :search_query_type, 'list'
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          'reversing would require removing all list search query types from search_queries'
  end

end

