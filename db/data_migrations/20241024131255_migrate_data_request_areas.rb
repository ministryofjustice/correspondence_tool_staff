# frozen_string_literal: true

class MigrateDataRequestAreas < ActiveRecord::DataMigration
  def data_request_area_type_for(request_type)
    case request_type
    when *DataRequest::BRANSTON_DATA_REQUEST_TYPES
      "branston"
    when *DataRequest::BRANSTON_REGISTRY_DATA_REQUEST_TYPES
      "branston_registry"
    when *DataRequest::MAPPA_DATA_REQUEST_TYPES
      "mappa"
    when *DataRequest::PRISON_DATA_REQUEST_TYPES + %w[cctv_and_bwcf] - %w[other]
      "prison"
    when *DataRequest::PROBATION_DATA_REQUEST_TYPES + %w[court] - %w[other]
      "probation"
    when "other"
      "other_department"
    end
  end

  def up
    # loop through the DataRequest records
    total = DataRequest.where(data_request_area_id: nil).count
    Rails.logger.info "Total - #{total}"
    DataRequest.includes(:commissioning_document, :data_request_emails).where(data_request_area_id: nil).find_each.with_index do |request, index|
      Rails.logger.info "Processing #{index} | #{((index / total.to_f) * 100).round}%" if (index % 100).zero?

      # Get the data_request_area_type for this request
      data_request_area_type = data_request_area_type_for(request.request_type)

      data_request_area = DataRequestArea.create!(
        user_id: request.user_id,
        case_id: request.case_id,
        data_request_area_type:,
        contact_id: request.contact_id,
        location: request.location.presence,
      )

      # Associate existing commissioning_document if present
      if request.commissioning_document.present?
        data_request_area.commissioning_document.destroy!
        request.commissioning_document.update_column(:data_request_area_id, data_request_area.id)
      end

      # Associate existing data_request_emails if present
      request.data_request_emails.each do |email|
        email.update_column(:data_request_area_id, data_request_area.id)
      end

      # Update DataRequest with the correct data_request_area_id
      request.update_column(:data_request_area_id, data_request_area.id)
    end
  end
end
