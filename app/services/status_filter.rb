class StatusFilter

  def initialize(arel, params)
    @arel = arel
    @params = params
  end


  def call
    if @params == 'closed'
      @arel.closed
    elsif @params == 'open'
      @arel.opened
    else
      raise ArgumentError.new("unrecognised status: #{@params}")
    end
  end
end
