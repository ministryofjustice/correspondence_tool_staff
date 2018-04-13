class SearchIndexUpdaterJob < ApplicationJob

  queue_as :search_index_updater

  def perform
    RavenContextProvider.set_context
    kases = Case::Base.where(dirty: true)
    kases.each do |kase|
      kase.update_index if kase.dirty?
      kase.mark_as_clean!
    end
  end
end
