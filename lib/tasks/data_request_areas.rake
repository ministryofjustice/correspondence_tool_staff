namespace :data_request_areas do
  desc "Set the denormalised location from the linked contact where location is blank"
  task backfill_blank_locations: :environment do
    areas_updated = ActiveRecord::Base.connection.exec_update(<<~SQL)
      UPDATE data_request_areas
      SET location = contacts.name,
          updated_at = NOW()
      FROM contacts
      WHERE contacts.id = data_request_areas.contact_id
        AND (data_request_areas.location IS NULL OR data_request_areas.location = '')
    SQL
    requests_updated = ActiveRecord::Base.connection.exec_update(<<~SQL)
      UPDATE data_requests
      SET location = data_request_areas.location,
          updated_at = NOW()
      FROM data_request_areas
      WHERE data_request_areas.id = data_requests.data_request_area_id
        AND (data_requests.location IS NULL OR data_requests.location = '')
        AND data_request_areas.location IS NOT NULL
        AND data_request_areas.location <> ''
    SQL
    puts "Updated #{areas_updated} data request area(s) with a blank location"
    puts "Updated #{requests_updated} data request(s) with a blank location"
  end

  desc "Overwrite the denormalised location from the linked contact for all data request areas and data requests"
  task force_sync_locations: :environment do
    areas_updated = ActiveRecord::Base.connection.exec_update(<<~SQL)
      UPDATE data_request_areas
      SET location = contacts.name,
          updated_at = NOW()
      FROM contacts
      WHERE contacts.id = data_request_areas.contact_id
    SQL
    requests_updated = ActiveRecord::Base.connection.exec_update(<<~SQL)
      UPDATE data_requests
      SET location = data_request_areas.location,
          updated_at = NOW()
      FROM data_request_areas
      WHERE data_request_areas.id = data_requests.data_request_area_id
        AND data_request_areas.location IS NOT NULL
        AND data_request_areas.location <> ''
    SQL
    puts "Updated #{areas_updated} data request area location(s) from the linked contact"
    puts "Updated #{requests_updated} data request location(s) from the data request area"
  end

  desc "Report data request areas and data requests whose denormalised location has drifted"
  task location_drift_report: :environment do
    drifted_areas = DataRequestArea
      .joins(:contact)
      .where("data_request_areas.location IS DISTINCT FROM contacts.name")
      .count
    drifted_requests = DataRequest
      .joins(:data_request_area)
      .where("data_request_areas.location IS NOT NULL AND data_request_areas.location <> ''")
      .where("data_requests.location IS DISTINCT FROM data_request_areas.location")
      .count

    puts "#{drifted_areas} data request area(s) with a location differing from the contact name"
    puts "#{drifted_requests} data request(s) with a location differing from the data request area"
    puts "Run data_request_areas:force_sync_locations to reconcile" if drifted_areas.positive? || drifted_requests.positive?
  end
end
