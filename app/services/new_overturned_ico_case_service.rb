class NewOverturnedIcoCaseService
  attr_reader :original_ico_appeal, :overturned_ico_case

  def initialize(ico_appeal_id)
    @original_ico_appeal = Case::Base.find(ico_appeal_id)
    @error = false
  end

  def error?
    @error
  end

  def success?
    !@error
  end

  def call
    case @original_ico_appeal.type
    when "Case::ICO::FOI"
      original_case = @original_ico_appeal.original_case
      reply_method = delivery_method_to_reply_method(original_case)
      overturned_klass = Case::OverturnedICO::FOI
    when "Case::ICO::SAR"
      original_case = @original_ico_appeal.original_case
      reply_method = original_case.reply_method
      overturned_klass = Case::OverturnedICO::SAR
    else
      @original_ico_appeal.errors.add(:base, "Invalid ICO appeal case type")
      @error = true
    end

    if success?
      @overturned_ico_case = overturned_klass.new(
        {
          email: original_case.email,
          ico_officer_name: @original_ico_appeal.ico_officer_name,
          original_case_id: original_case.id,
          original_ico_appeal_id: @original_ico_appeal.id,
          postal_address: original_case.postal_address,
          reply_method:,
          flag_for_disclosure_specialists: original_case.flagged? ? "yes" : nil,
        },
      )
    end
  end

private

  def delivery_method_to_reply_method(kase)
    if kase.sent_by_email?
      :send_by_email
    else
      :send_by_post
    end
  end
end
