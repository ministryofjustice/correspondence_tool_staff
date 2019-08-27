class DataRequestUpdateService
  attr_reader :result, :data_request

  def initialize(user:, data_request:, params:)
    @result = nil
    @case = data_request.kase
    @user = user
    @data_request = data_request
    @params = params
  end

  def call
    ActiveRecord::Base.transaction do
      begin
        @result = :unprocessed
        return if empty_params?

        @data_request.date_received = nil # Reset to force validation
        @data_request.update!(@params)

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

    pages_description = [
      @data_request.num_pages,
      I18n.t('.log_pages', scope: scope, count: @data_request.num_pages)
    ].join(' ')

    I18n.t('.log_message',
      location: @data_request.location,
      pages: pages_description,
      date_received: @data_request.date_received.strftime('%F'),
      scope: scope
    )
  end

  def empty_params?
    @params[:num_pages].blank? &&
      %i[
        date_received_dd
        date_received_mm
        date_received_yyy
      ].all? { |field| @params[field].blank? }
  end
end
