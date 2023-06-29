class SearchTestDataSeeder
  def initialize
    @show = CTS::Cases::Show.new
  end

  def run
    @case_count = 0
    while @case_count < 200
      create_case
      @case_count += 1
    end
    Case::Base.update_all_indexes
  end

  def create_case
    creator = User.all.sample
    params = ActiveSupport::HashWithIndifferentAccess.new({
      type: select_type,
      name: select_name,
      email: select_email,
      postal_address: select_postal_address,
      requester_type: select_requester_type,
      delivery_method: select_delivery_method,
      subject: select_subject,
      message: select_message,
      flag_for_team: set_flagged,
      responding_team: select_responding_team,
      target_state: select_target_state,
      creator:,
    })
    params[:received_date] = select_received_date(params[:target_state])
    params[:created_at] = select_created_at(params[:received_date])

    case_creator = CTS::Cases::Create.new(Rails.logger, params)
    @case = case_creator.new_case
    selected_state = params["target_state"]
    if @case.valid?
      case_creator.call(selected_state, @case)
      Rails.logger.debug "Case created: #{@case.number}"
      @show.call(@case)
    else
      Rails.logger.debug "Failed for these params: "
      Rails.logger.debug params
      Rails.logger.debug "with these errors: "
      Rails.logger.debug @case.errors.full_messages
    end
  end

  def select_type
    @types ||= [
      "Case::FOI::Standard",
      "Case::FOI::ComplianceReview",
      "Case::FOI::TimelinessReview",
      "Case::FOI::Standard",
    ]
    @types[@case_count % @types.length]
  end

  def select_name
    @names ||= [
      "Noam Chomsky",
      "Bert Vaux",
      "Steven Pinker",
      "Edward Sapir",
      "Benjamin Whorf",
      "Ben Whorf",
      "Ludwig Wittgenstein",
      "Peter Ladefoged",
      "Jonathon Edwards",
      "Sue Savage-Rumbaugh",
      "Nim Chimpsky",
      "Andrew Carnie",
      "Kanzi",
    ]
    @names[@case_count % @names.length]
  end

  def select_email
    "#{select_name.gsub(/\s+/, '')}@gerlach.com"
  end

  def select_postal_address
    @addresses ||= [
      "10 Downing Street\r\nWestminster\r\nLondon\r\nSW1A 2AA",
      "221B Baker Street\r\nLondon\r\n NW1 6XE",
      "10 The Circus\r\nBath\r\nBA1 2EW",
      "The Castle,\r\nPalace Green,\r\nDurham,\r\nDH1 3RW",
      "4 Privet Drive,\r\n Little Whinging,\r\n Surrey",
      "Warwick Castle\r\nWarwick\r\nCV34 4QU",
      "York Minster\r\nDeangate\r\nYork\r\nYO1 7HH",
      "12 Buxton Road,\r\n Castleton,\r\n Hope Valley\r\nS33 8WP",
      "1 Marlborough Rd,\r\n St. James's,\r\n London \r\nSW1A 1BS",
      nil,
    ]
    @addresses[@case_count % @addresses.length]
  end

  def select_requester_type
    @req_type ||= %w[
      academic_business_charity
      journalist
      member_of_the_public
      offender
      solicitor
      staff_judiciary
      what_do_they_know
    ]
    @req_type[@case_count % @req_type.length]
  end

  def select_received_date(target_state)
    dates ||= [
      8.business_days.ago,
      20.business_days.ago,
      50.business_days.ago,
      70.business_days.ago,
    ]
    if target_state_before_response_uploaded?(target_state)
      dates << 1.business_days.ago
      dates << 3.business_days.ago
    end

    0.business_days.after(dates[@case_count % dates.length]).to_date
  end

  def select_created_at(received_date)
    0.business_days.after(received_date).to_s
  end

  def select_delivery_method
    # Sent by post needs a document uploaded on case creation which CTS does not currently handle
    @delivery_method ||= [
      # 'sent_by_post',
      "sent_by_email",
    ]

    @delivery_method[@case_count % @delivery_method.length]
  end

  def select_subject
    @subject ||= [
      "Prisoner releases in the past 3 months",
      "Cost of prison meals",
      "Prison riot records",
      "Court fees changes 2015",
      "Release on tempory licence numbers",
      "Mobile phone seizures in England",
      "Sex offenders treatment",
      "funding of digital",
    ]
    @subject[@case_count % @subject.length]
  end

  def select_message
    @messages ||= [
      "I would like to know how many prisoners have been released from HM Feltham in the past 3 months from June of this year",
      "Are prison meals expensive? and how many food options do they have? Oh I do wish I knew",
      "How far back do your records of riots go?",
      "Please tell me under the FOIA what chages there were to court fees in 2015",
      "Are prisoner still released on tempory licence? if so please tell me how many have been in the past 5 years",
      "With the rise in technology has there been a rise in the number of mobile phone seizures in prisons in England. Could I have the numbers of phone that have been seized across the past 20 years",
      "What treatment is offered to sex offenders in institutions across the UK",
      "How much money is spend at the MOJ digital team, specifically how much is spent on: i) coffee, ii) laptops, iii) cables",
    ]
    @messages[@case_count % @messages.length]
  end

  def set_flagged
    @flag_status ||= ["disclosure", "press", "private", nil]
    @flag_status[@case_count % @flag_status.length]
  end

  def select_responding_team
    @responding_teams ||= BusinessUnit.responding.active.map { |team| team.id.to_s }

    @responding_teams.to_a[@case_count % @responding_teams.length]
  end

  def select_target_state
    case set_flagged
    when "press", "private"
      select_target_state_full
    when "disclosure"
      select_target_state_trigger
    else
      select_target_state_standard
    end
  end

  def select_target_state_full
    @states ||= %w[
      unassigned
      awaiting_responder
      drafting
      pending_dacu_clearance
      pending_press_office_clearance
      pending_private_office_clearance
      awaiting_dispatch
      responded
      closed
    ]
    @states[@case_count % @states.length]
  end

  def target_state_before_response_uploaded?(target_state)
    target_state.in?(%w[unassigned awaiting_responder drafting])
  end

  def select_target_state_trigger
    @states ||= %w[
      unassigned
      awaiting_responder
      drafting
      pending_dacu_clearance
      awaiting_dispatch
      responded
      closed
    ]
    @states[@case_count % @states.length]
  end

  def select_target_state_standard
    @states ||= %w[
      unassigned
      awaiting_responder
      drafting
      awaiting_dispatch
      responded
      closed
    ]
    @states[@case_count % @states.length]
  end
end
