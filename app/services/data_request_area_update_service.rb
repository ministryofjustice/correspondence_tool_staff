class DataRequestAreaUpdateService
  attr_reader :result, :data_request, :data_request_area

  def initialize(user:, params:, data_request_area:)
    @result = nil
    @case = data_request_area.kase
    @user = user
    @data_request_area = data_request_area
    @data_request = data_request
    @params = params
  end

  def call
    ActiveRecord::Base.transaction do
      @result = :unprocessed

      @data_request_area.assign_attributes(@params.merge!(user_id: @user.id))
      next unless @data_request_area.changed?

      @data_request_area.save!

      @case.state_machine.add_data_received!(
        acting_user: @user,
        acting_team: BusinessUnit.dacu_branston,
        message: "Data request location updated",
        )

      @result = :ok
    rescue ActiveRecord::RecordInvalid, ActiveRecord::AssociationTypeMismatch
      @result = :error
    end
  end
end

