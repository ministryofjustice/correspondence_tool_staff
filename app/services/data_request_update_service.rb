class DataRequestUpdateService
  attr_reader :result, :data_request

  def initialize(user:, data_request:, params:)
    @result = nil
    @case = data_request.kase
    @user = user
    @data_request = data_request
    @params = params
    @old_num_pages = @data_request.cached_num_pages
  end

  def call
    ActiveRecord::Base.transaction do
      @result = :unprocessed

      @data_request.assign_attributes(@params.merge!(user_id: @user.id))
      next unless @data_request.changed?

      @data_request.save!

      @case.state_machine.add_data_received!(
        acting_user: @user,
        acting_team: BusinessUnit.dacu_branston,
        message: log_message,
      )

      @result = :ok
    rescue ActiveRecord::RecordInvalid, ActiveRecord::AssociationTypeMismatch
      @result = :error
    end
  end

private

  def log_message
    scope = "cases.data_requests.update"
    old_pages = @old_num_pages
    new_pages = @data_request.cached_num_pages

    if old_pages != new_pages
      # i18n-tasks-use t('cases.data_requests.update.log_message_pages_changed')
      I18n.t(".log_message_pages_changed",
             request_type: I18n.t("helpers.label.data_request.request_type.#{data_request.request_type}"),
             location: @data_request.data_request_area.location,
             date_changed: Date.current.strftime("%F"),
             old_pages:,
             new_pages:,
             scope:)
    else
      ""
    end
  end
end
