class AddTypeToTeams < ActiveRecord::Migration[5.0]
  class Team < ApplicationRecord
  end

  def up
    Team.connection.transaction do
      add_column :teams, :type, :string

      Team.all.each do |team|
        team.update(type: "BusinessUnit")
      end

      add_index :teams, :type
    end
  end

  def down
    Team.connection.transaction do
      remove_index :teams, :type
      remove_column :teams, :type, :string
    end
  end
end
