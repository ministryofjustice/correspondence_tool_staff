class DeadlineFilter

  def initialize(arel, params)
    @arel = arel
    @params = params        # external_deadline_from_dd
                            # external_deadline_from_mm
                            # external_deadline_from_yy
                            # external_deadline_to_dd
                            # external_deadline_to_mm
                            # external_deadline_to_yy
  end

  def call
    from_date = Date.new(@params[:external_deadline_from_yy],
                          @params[:external_deadline_from_mm],
                          @params[:external_deadline_from_dd])

    to_date = Date.new(@params[:external_deadline_to_yy],
                        @params[:external_deadline_to_mm],
                        @params[:external_deadline_to_dd])
    @range = from_date..to_date
  end

  private

  def deadline_is_within_period(params)
    @arel.where(external_deadline === @range)
  end
end
