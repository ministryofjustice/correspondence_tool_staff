namespace :search do
  desc "Re-enqueue search indexing for cases still flagged as dirty"
  task reindex_dirty_cases: :environment do
    case_ids = Case::Base.where(dirty: true).pluck(:id)
    case_ids.each do |case_id|
      SearchIndexUpdaterJob.perform_later(case_id)
    end
  end

  desc "Re-index all cases"
  task reindex_all_cases: :environment do
    Case::Base.update_all_indexes
  end
end
