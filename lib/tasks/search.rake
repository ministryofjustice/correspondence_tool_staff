namespace :search do
  desc "Re-enqueue search indexing for cases still flagged as dirty"
  task reindex_dirty_cases: :environment do
    case_ids = Case::Base.where(dirty: true).pluck(:id)
    case_ids.each do |case_id|
      SearchIndexUpdaterJob.perform_later(case_id)
    end
  end
end
