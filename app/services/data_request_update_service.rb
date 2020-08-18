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
      begin
        @result = :unprocessed

        @data_request.assign_attributes(@params.merge!(user_id: @user.id))
        return unless @data_request.changed?

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
  end


  private

  def log_message
    scope = 'cases.data_requests.update'

    # Create nicely readable sentences for both old and new number of pages
    # i18n-tasks-use t('cases.data_requests.update.log_pages')
    pages = [@old_num_pages, @data_request.cached_num_pages].map do |n|
      "#{n} #{I18n.t('.log_pages', scope: scope, count: n)}"
    end

    # i18n-tasks-use t('cases.data_requests.update.log_message')
    I18n.t('.log_message',
      request_type: @data_request.request_type,
      location: @data_request.location,
      date_received: Date.current.strftime('%F'),
      old_pages: pages.first,
      new_pages: pages.second,
      scope: scope
    )
  end

  # Allowing a user to create a new DataRequestLog which is a duplicate of the
  # current total number of pages/date received is not currently considered a
  # model error but rather a UX issue. Hence the check for unchanged? in this
  # service rather than within the DataRequest model
  def unchanged?(new_data_request_log)
    @data_request.cached_num_pages_was == new_data_request_log.num_pages &&
      @data_request.cached_date_received_was == new_data_request_log.date_received
  end
end
