class DataRequestAreaCreateService
  attr_reader :result, :case, :data_request_area

  def initialize(kase:, user:, data_request_area_params:)
    @result = nil
    @user = user
    @case = kase
    @data_request_area = build_data_request_area(data_request_area_params)
  end

  def call
    ActiveRecord::Base.transaction do
      @result = :unprocessed
      next if @data_request_area.blank?

      @case.save!
      @result = :ok
    rescue ActiveRecord::RecordInvalid, ActiveRecord::AssociationTypeMismatch
      @result = :error
    end
  end

private

  def build_data_request_area(data_request_area_params)
    return nil unless @case.respond_to? :data_request_areas

    @case.data_request_areas.new(data_request_area_params.merge(user_id: @user.id))
  end
end
