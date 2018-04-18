class SearchTestDataSeeder
  #
  def initialize
    @responding_teams = BusinessUnit.responding.map {|team| team.id.to_s }
    @case_count = 0
  end

  def run
    while @case_count < 200
      create_case(@case_count)
      @case_count += 1
    end
  end

  def create_case(index)
    params = HashWithIndifferentAccess.new({
        "case"=>{
            "type"=> chose_type[index % 4 ],
            "name"=> chose_name[index % 13 ],
            "email"=>chose_email,
            "postal_address"=>chose_postal_address[index % 10 ],
            "requester_type"=>chose_requester_type[index % 7 ],
            received_date: chose_received_date[index % 5 ],
            "created_at"=>"2018-04-05 09:00:00 +0100",
            "delivery_method"=>chose_delivery_method[index % 2 ],
            "subject"=>chose_subject[index % 7 ],
            "message"=> chose_message[index % 2 ],
            "flagged_for_disclosure_specialist_clearance"=>set_flagged_for_disclosure[index % 3 ],
            "flagged_for_press_office_clearance"=>set_flagged_for_press_and_private_office(index),
            "flagged_for_private_office_clearance"=>set_flagged_for_press_and_private_office(index),
            "responding_team"=>chose_responding_team[index % 7 ],
            "target_state"=>chose_target_state(index)
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
      @case.responding_team = BusinessUnit.find(
          params['case']['responding_team']
      )
      # prepare_flagged_options_for_displaying
      # @target_states = available_target_states
      # @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')
    end
  end

  def chose_type
    ["Case::FOI::Standard", "Case::FOI::ComplianceReview", "Case::FOI::TimelinessReview", "Case::FOI::Standard"]
  end

  def chose_name
    [
      "Noam Chomsky", "Bert Vaux", "Steven Pinker",
      "Edward Sapir", "Benjamin Whorf", "Ben Whorf",
      "Ludwig Wittgenstein", "Peter Ladefoged", "Jonathon Edwards",
      "Sue Savage-Rumbaugh", "N Chomsky", "Andrew Carnie", "Kanzi"
    ]
  end

  def chose_email
    "#{"name".gsub(/\s+/, "")}@gerlach.com"
  end

  def chose_postal_address
    [
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
  end

  def chose_requester_type
    [
      'academic_business_charity',
      'journalist',
      'member_of_the_public',
      'offender',
      'solicitor',
      'staff_judiciary',
      'what_do_they_know'
    ]
  end

  def chose_received_date
    [Date.today - 3, Date.today - 5, Date.today - 17, Date.today - 30,  Date.today - 60]
  end

  def chose_delivery_method
    [
      'sent_by_post',
      'sent_by_email',
    ]
  end

  def chose_subject
    [
      "Prisoner releases in the past 3 months",
      "Cost of prison meals",
      "Prison riot records",
      "Court fees changes 2015",
      "Release on tempory licence numbers",
      "Mobile phone seizures in England",
      "Sex offenders treatment",
      "funding of digital"
    ]
  end

  def chose_message
  [
    "x",
    "y"
  ]
  end

  def set_flagged_for_disclosure
    ['0', '1', '1']
  end

  def set_flagged_for_press_and_private_office(index)
    if set_flagged_for_disclosure[index % 3] == '0'
      '0'
    else
      ['0', '1'][index % 2]
    end
  end

  def chose_responding_team
    @responding_teams.to_a
  end

  def chose_target_state(index)
    if set_flagged_for_press_and_private_office(index)[index % 2] == 1
      chose_target_state_full[index % 9]
    elsif set_flagged_for_disclosure[index % 2] == 1
      chose_target_state_trigger[index % 7]
    else
      chose_target_state_standard[index % 6]
    end
  end

  def chose_target_state_full
    [
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
  end

  def chose_target_state_trigger
    [
    "unassigned",
    "awaiting_responder",
    "drafting",
    "pending_dacu_clearance",
    "awaiting_dispatch",
    "responded",
    "closed"
  ]
  end

  def chose_target_state_standard
    [
    "unassigned",
    "awaiting_responder",
    "drafting",
    "awaiting_dispatch",
    "responded",
    "closed"
  ]
  end


end
