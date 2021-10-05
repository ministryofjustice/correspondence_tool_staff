class SearchIndexUpdaterJob < ApplicationJob

  queue_as :search_index_updater

  def perform(case_id)
    RavenContextProvider.set_context
    kase=Case::Base.find(case_id)
    if kase
      kase.update_index
      kase.mark_as_clean!
    end
  end
end
