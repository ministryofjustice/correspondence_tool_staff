class SearchIndexBuNameUpdaterJob < ApplicationJob

  queue_as :search_index_updater

  def perform(team_id)
    SentryContextProvider.set_context
    bu = BusinessUnit.find(team_id)
    bu.responding_cases.each do | kase |
      SearchIndexUpdaterJob.perform_later(kase.id)
    end
  end
end
