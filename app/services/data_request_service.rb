class DataRequestService
  attr_reader :result, :data_request

  def initialize(kase:, user:, params:)
    @result = nil
    @case = kase
    @user = user
    @location = params[:location]
    @data = params[:data]
  end

  def call
    ActiveRecord::Base.transaction do
      begin
        @data_request = DataRequest.new(
          offender_sar_case: @case,
          user: @user,
          location: @location,
          data: @data,
        )
        @data_request.save!
        @result = :ok
      rescue ActiveRecord::RecordInvalid, ActiveRecord::AssociationTypeMismatch
        @result = :error
      end
    end
  end
end
