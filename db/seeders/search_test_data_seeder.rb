class SearchTestDataSeeder

  def initialize
    @responding_teams = BusinessUnit.responding.map { |team| team.id.to_s}
  end

  def run
    @index= 0
    while @index < 200
      create_case(@index)
      @index += 1
    end
  end

  def create_case(index)
    params = HashWithIndifferentAccess.new({
        "case"=>{
            "type"=> chose_type,
            "name"=> chose_name,
            "email"=>chose_email,
            "postal_address"=>chose_postal_address,
            "requester_type"=>chose_requester_type,
            received_date: chose_received_date,
            "created_at"=>"2018-04-05 09:00:00 +0100",
            "delivery_method"=>chose_delivery_method,
            "subject"=>chose_subject,
            "message"=> chose_message,
            "flagged_for_disclosure_specialist_clearance"=>set_flagged_for_disclosure,
            "flagged_for_press_office_clearance"=>set_flagged_for_press_and_private_office,
            "flagged_for_private_office_clearance"=>set_flagged_for_press_and_private_office,
            "responding_team"=>chose_responding_team,
            "target_state"=>chose_target_state
        },
        "commit"=>"Create Case"
    })

     case_creator = CTS::Cases::Create.new(Rails.logger, params['case'])
    @case = case_creator.new_case
    @selected_state = params['case']['target_state']
    ap params[:case]
    if @case.valid?
      case_creator.call([@selected_state], @case)
      puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
      puts "Case created: #{@case.number}"
      puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    else
      puts @case.errors.full_messages
      @case.responding_team = BusinessUnit.find(
          params['case']['responding_team']
      )
      # prepare_flagged_options_for_displaying
      # @target_states = available_target_states
      # @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')
    end
  end

  def chose_type
    types = [
              "Case::FOI::Standard",
              "Case::FOI::ComplianceReview",
              "Case::FOI::TimelinessReview",
              "Case::FOI::Standard"
            ]
    types[@index % types.length]
  end

  def chose_name
    names = [
              "Noam Chomsky", "Bert Vaux", "Steven Pinker",
              "Edward Sapir", "Benjamin Whorf", "Ben Whorf",
              "Ludwig Wittgenstein", "Peter Ladefoged", "Jonathon Edwards",
              "Sue Savage-Rumbaugh", "N Chomsky", "Andrew Carnie", "Kanzi"
            ]
    names[@index % names.length]
  end

  def chose_email
    "#{"name".gsub(/\s+/, "")}@gerlach.com"
  end

  def chose_postal_address
    addresses = [
                "10 Downing Street\r\nWestminster\r\nLondon\r\nSW1A 2AA",
                "221B Baker Street\r\nLondon\r\n NW1 6XE",
                "10 The Circus\r\nBath\r\nBA1 2EW",
                "The Castle,\r\nPalace Green,\r\nDurham,\r\nDH1 3RW",
                "4 Privet Drive,\r\n Little Whinging,\r\n Surrey",
                "Warwick Castle\r\nWarwick\r\nCV34 4QU",
                "York Minster\r\nDeangate\r\nYork\r\nYO1 7HH",
                "12 Buxton Road,\r\n Castleton,\r\n Hope Valley\r\nS33 8WP",
                "1 Marlborough Rd,\r\n St. James's,\r\n London \r\nSW1A 1BS",
                nil
              ]
    addresses[@index % addresses.length]
  end

  def chose_requester_type
    req_type = [
                'academic_business_charity',
                'journalist',
                'member_of_the_public',
                'offender',
                'solicitor',
                'staff_judiciary',
                'what_do_they_know'
              ]
    req_type[@index % req_type.length]
  end

  def chose_received_date
    dates = [
              Date.today - 1,
              Date.today - 3,
              Date.today - 5,
              Date.today - 17,
              Date.today - 19,
              Date.today - 20,
              Date.today - 29,
              Date.today - 30,
              Date.today - 50,
              Date.today - 60,
              Date.today - 70
            ]
    dates[@index % dates.length]
  end

  def chose_delivery_method
    delivery_method = [
                      # 'sent_by_post',
                      'sent_by_email',
                      ]

    delivery_method[@index % delivery_method.length]
  end

  def chose_subject
    subject = [
                "Prisoner releases in the past 3 months",
                "Cost of prison meals",
                "Prison riot records",
                "Court fees changes 2015",
                "Release on tempory licence numbers",
                "Mobile phone seizures in England",
                "Sex offenders treatment",
                "funding of digital"
              ]
    subject[@index % subject.length]
  end

  def chose_message
    messages = [
              "I would like to know how many prisoners have been released from HM Feltham in the past 3 months from June of this year",
              "Are prison meals expensive? and how many food options do they have? Oh I do wish I knew",
              "How far back do your records of riots go?",
              "Please tell me under the FOIA what chages there were to court fees in 2015",
              "Are prisoner still released on tempory licence? if so please tell me how many have been in the past 5 years",
              "With the rise in technology has there been a rise in the number of mobile phone seizures in prisons in England?
                could I have the numbers of phone that have been seized across the past 20 years",
              "What treatment is offered to sex offenders in institutions across the UK",
              "How much money is spend at the MOJ digital team, specifically how much is spent on: i) coffee, ii) laptops, iii) cables"
            ]
    messages[@index % messages.length]
  end

  def set_flagged_for_disclosure
    # [1, 0, 1][@index % 2]
    # flag_status[@index % flag_status.length]
    1
  end

  def set_flagged_for_press_and_private_office
    # if set_flagged_for_disclosure[@index % 4] == 0
    #   0
    # else
      # flag_status = ["0", "1"]
      # return flag_status[@index % flag_status.length]
    # end
    # [1, 0][@index % 2]
    1
  end

  def chose_responding_team
    @responding_teams.to_a[ @index % @responding_teams.length]
  end

  def chose_target_state
    if set_flagged_for_press_and_private_office == 1
      chose_target_state_full
    elsif set_flagged_for_disclosure == 1
      chose_target_state_trigger
    else
      chose_target_state_standard
    end
  end

  def chose_target_state_full
    states = [
              "unassigned",
              "awaiting_responder",
              "drafting",
              "pending_dacu_clearance",
              "pending_press_office_clearance",
              "pending_private_office_clearance",
              "awaiting_dispatch",
              "responded",
              "closed"
            ]
    states[@index % states.length]

  end

  def chose_target_state_trigger
    states = [
              "unassigned",
              "awaiting_responder",
              "drafting",
              "pending_dacu_clearance",
              "awaiting_dispatch",
              "responded",
              "closed"
            ]
    states[@index % states.length]
  end

  def chose_target_state_standard
    states = [
              "unassigned",
              "awaiting_responder",
              "drafting",
              "awaiting_dispatch",
              "responded",
              "closed"
            ]
  states[@index % states.length]
  end
end
