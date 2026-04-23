module DbHousekeeping
  def self.clean(seed: true)
    tables = %w[
      bank_holidays
      assignments
      cases
      case_attachments
      case_closure_metadata
      case_number_counters
      case_transitions
      cases_exemptions
      feedback
      team_correspondence_type_roles
      team_properties
      teams
      teams_users_roles
      users
      correspondence_types
      cases_users_transitions_trackers
      linked_cases
      search_queries
      warehouse_case_reports
      report_types
      letter_templates
      category_references
    ]
    tables.each do |table|
      ActiveRecord::Base.connection.execute("TRUNCATE #{table} CASCADE")
    end
    seed_database_for_tests if seed
  end
end
