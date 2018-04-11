class SearchTestDataSeeder



  def run
    params = HashWithIndifferentAccess.new({
        "case"=>{
            "type"=>"Case::FOI::Standard",
            "name"=>"Mrs. Petra Turcotte",
            "email"=>"petra_mrs_turcotte@gerlach.org",
            "postal_address"=>"2, Vinery Way\r\nLondon\r\nW6 0LQ",
            "requester_type"=>"journalist",
            received_date: "2018-04-05",
            "created_at"=>"2018-04-05 09:00:00 +0100",
            "delivery_method"=>"sent_by_email",
            "subject"=>"Horizontal intermediate migration",
            "message"=>"Conitor aegrotatio aegre defungo. Odio sunt confido congregatio allatus sum. Natus compello beatae. Tantillus vero conturbo curo defleo comburo. Spoliatio delego articulus defigo ut. Appello ambulo absorbeo. Carcer eligendi delicate vivo conatus contabesco consuasor. Considero tollo caste ventosus defluo saepe varius. Vaco adinventitias taceo caveo adsuesco. Quia vulticulus ut una corroboro. Et celebrer vulticulus comedo verecundia arceo calcar. Vesper turbo vinitor cena. Amiculum vel aperte suus theologus cupiditas accusantium. Commodi cupressus currus voveo.",
            "flagged_for_disclosure_specialist_clearance"=>"0",
            "flagged_for_press_office_clearance"=>"0",
            "flagged_for_private_office_clearance"=>"0",
            "responding_team"=>"18",
            "target_state"=>"drafting"
        },
        "commit"=>"Create Case"
    })

     case_creator = CTS::Cases::Create.new(Rails.logger, params['case'])
    @case = case_creator.new_case
    @selected_state = params['case']['target_state']
    if @case.valid?
      case_creator.call([@selected_state], @case)
      puts "Case created: #{@case.number}"
    else
      @case.responding_team = BusinessUnit.find(
          params['case']['responding_team']
      )
      # prepare_flagged_options_for_displaying
      # @target_states = available_target_states
      # @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')
      render :new
    end
  end


end

