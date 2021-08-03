#rubocop:disable Lint/RedundantCopDisableDirective, Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/MethodLength
class LetterTemplateSeeder
  def seed!
    puts "---- Seeding Letter Templates ----"
    # Reciever for prision related string
    prison_receiver = <<~EOF
        <%= letter.name %><% if values.prison_number.present? %> - <%= values.first_prison_number %><% end %>
    EOF
    solictor_receiver = <<~EOF
      <% if letter.name.present? %><%= letter.name %><% end %><% if values.third_party_company_name.present? %><%= values.third_party_company_name %><% end %>
    EOF
    address = <<~EOF
      <%= letter.address.gsub("\n", "<br>").html_safe %>
    EOF

    rec = LetterTemplate.find_by(abbreviation: 'prisoner-acknowledgement')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Prisoner acknowledgement letter',
                abbreviation: 'prisoner-acknowledgement',
                template_type: 'acknowledgement',
                body: <<~EOF
                  <p>
                  <br><br>Dear <%= values.requester_name %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br>
                  <br>Thank you for your Subject Access Request (SAR) dated <%= values.request_dated&.strftime('%e %B %Y') %>.
                  <br>
                  <br>To complete the SAR we will have to identify information from a number of business areas, including prison establishments. In view of this there is very little information we can provide in response to enquiries. We aim to process your SAR within one calendar month, and it would be helpful if you could limit any communication with the office during this period.   
                  <br>
                  <br>Her Majesty’s Prison and Probation Service (HMPPS) holds routine information that can be disclosed to you as part of business as usual requests, without submitting a formal SAR. Please find enclosed a list of documents that can be provided to you by your keyworker in the prison or your probation office. As some of the information requested can be disclosed directly to you, we will be forwarding your request to the relevant business area to take forward and the documents listed will not be included in your SAR response.
                  <br>
                  <br>Please also note if you have requested medical information as part of the request, the responsibility for providing medical information has transferred to the National Health Service/ Clinical Commissioning Groups. If you require medical information, please contact the Healthcare Services team in the prison.
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Application Team
                  <br>Data Protection Compliance Team
                  <br>Ministry of Justice
                  </p>
                EOF
                )
    rec.update!(letter_address: <<~EOF
                  #{prison_receiver}
                  <br>#{address}
                EOF
                )

    rec = LetterTemplate.find_by(abbreviation: 'prisoner-disclosed-cover-letter')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Prisoner disclosed cover letter',
                abbreviation: 'prisoner-disclosed-cover-letter',
                template_type: 'dispatch',
                body: <<~EOF
                  <p>
                  <br><br>Dear Colleague
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %> - <%= values.first_prison_number %></strong>
                  <br>
                  <br>Please find enclosed documents relating to a Subject Access Request (SAR) made under the Data Protection Act 2018 by the above offender.
                  <br>
                  <br><strong>This letter must not be seen by the offender. Once the parcel has been passed to the offender please ensure this covering letter is destroyed securely.</strong>
                  <br>
                  <br>Following inappropriate articles being found in official correspondence and subsequent security alert email issued on 5 March 2015; if you are suspicious about the content of this parcel it should be opened in the presence of the offender, contents checked and passed to them immediately.
                  <br>
                  <br>If you have any queries relating to these instructions or concerns regarding the parcel please contact our team immediately on 01283 496066. Do not deliver the SAR to the offender or forward the parcel on to another prison. Alternatively, you can return the SAR to our team at the address above with a covering letter outlining your concerns.
                  <br>
                  <br>Thank you for your assistance in this matter.
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Despatch Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                EOF
                )
    rec.update!(letter_address: <<~EOF
                  EO Custody Office
                  <br><%= letter.format_address(values.subject_address).gsub("\n", "<br>").html_safe %>
                EOF
                )

    rec = LetterTemplate.find_by(abbreviation: 'prisoner-disclosed')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Prisoner disclosed letter',
                abbreviation: 'prisoner-disclosed',
                template_type: 'dispatch',
                body: <<~EOF
                  <p>
                  <br><br>Dear <%= values.recipient_name %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br>
                  <br>I am writing in response to your request for information made under the Data Protection Act 2018 (DPA).
                  <br>
                  <br>Enclosed is all the information related to your request that I am able to release. Some information may have been withheld and this is because the information is exempt from disclosure under the DPA. The exemptions within the DPA include information which is processed for the prevention or detection of a crime or the apprehension or prosecution of offenders, and information that would identify third parties. Where we have withheld exempt information, you will see items redacted on the documents.
                  <br>
                  <br>I can confirm that the personal data contained within these documents is being processed by the Ministry of Justice for the purposes of the administration of justice and for the exercise of any functions of the Crown, a Minister of the Crown or a government department. As such we may share or exchange data with other Departments or organisations if it is lawful to do so, for example the Police or the Probation Service.
                  <br>
                  <br>If you have any queries regarding your request please contact the Offender Subject Access Request Team, at the address above. It is also open to you to ask the Information Commissioner to look into the case. You can contact the Information Commissioner at this address:
                  <br>
                  <br>Information Commissioner's Office, Wycliffe House, Water Lane, Wilmslow, Cheshire, SK9 5AF
                  <br>Internet: ico.org.uk
                  <br>
                  <br>Please note that copies of the data provided to you will be retained for no longer than nine months. Once this period has passed, we will be unable to answer any questions you may have or provide duplicates of this information. It will not normally be disclosed in any future SARs.
                  <br>
                  <br>Finally, I would like to suggest that you do not keep this information where it can be accessed by others. Once you have read through the information it can be placed in your stored property.
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Despatch Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                EOF
                )
    rec.update!(letter_address: <<~EOF
                  #{prison_receiver}
                  <br>#{address}
                EOF
                )

    rec = LetterTemplate.find_by(abbreviation: 'prisoner-disclosed-covid')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Prisoner disclosed letter (COVID-19)',
                abbreviation: 'prisoner-disclosed-covid',
                template_type: 'dispatch',
                body: <<~EOF
                  <p>
                  <br><br>Dear <%= values.recipient_name %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br>
                  <br>I am writing in response to your request for information made under the Data Protection Act 2018 (DPA).
                  <br>
                  <br>During this unprecedented period of our history the Ministry of Justice (MoJ) is continuing to deliver its critical services, with a focus on those areas where resources are immediately required. For this reason and to support our colleagues in Her Majesty's Prison and Probation Service (HMPPS), we are only able to provide you with a copy of the personal information enclosed and not all the information that you requested.
                  <br>
                  <br>Some information may have been withheld because it is exempt from disclosure under the DPA. Where we have withheld exempt information, you will see redactions on the documents. The exemptions for withholding information within the DPA include information which is processed for the prevention or detection of a crime or the apprehension or prosecution of offenders, and information that relates to and would identify third parties
                  <br>
                  <br>I can confirm that the personal data contained within these documents is being processed by the MoJ for the purposes of the administration of justice and for the exercise of any functions of the Crown, a Minister of the Crown or a government department. As such we may share or exchange personal data with other departments or organisations if it is lawful to do so, for example the police or the probation services
                  <br>
                  <br>If you have any queries regarding your request please contact the Offender Subject Access Request Team, at the address above. It is also open to you to ask the Information Commissioner to look into the case. You can contact the Information Commissioner at this address: Information Commissioner's Office, Wycliffe House, Water Lane, Wilmslow, Cheshire, SK9 5AF Internet: ico.org.uk
                  <br>
                  <br>Please note that copies of the data provided to you will be retained for no longer than nine months. Once this period has passed, we will be unable to answer any questions you may have or provide duplicates of this information. It will not normally be disclosed in any future SARs. I would like to suggest that you do not keep this information where it can be accessed by others. Once you have read through the information it can be placed in your stored property.
                  <br>
                  <br>Finally, should you require a copy of any other personal information held by the MoJ we advise you to contact your key worker within the prison who can provide support regarding the disclosure of routine information that does not need to be provided through a formal SAR.
                  <br>
                  <br>After the COVID-19 pandemic or as soon as reasonably practicable (based on Government and Public Health England guidance), we will revert to the provision of full services. We apologise for any inconvenience the reduced but pragmatic service may cause you.
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Despatch Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                EOF
                )
    rec.update!(letter_address: <<~EOF
                  #{prison_receiver}
                  <br>#{address}
                EOF
                )

    rec = LetterTemplate.find_by(abbreviation: 'solicitor-acknowledgement')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Solicitor acknowledgement letter',
                abbreviation: 'solicitor-acknowledgement',
                template_type: 'acknowledgement',
                body: <<~EOF
                  <p>
                  <% if values.recipient == "requester_recipient" %><br><br>Dear Sirs<% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %> - <%= values.first_prison_number %></strong>
                  <br>
                  <br>Thank you for your subject access request (SAR) dated <%= values.request_dated&.strftime('%e %B %Y') %>.
                  <br>
                  <br>To complete the SAR we will have to identify information from a number of business areas, including prison establishments. In view of this there is very little information we can provide in response to enquiries. We aim to process your SAR within one calendar month, and it would be helpful if you could limit any communication with the office during this period. 
                  <br>
                  <br>Her Majesty’s Prison and Probation Service (HMPPS) holds routine information that can be disclosed to you or your client as part of business as usual requests, without submitting a formal SAR. Please find enclosed a list of documents that can be provided by your client’s keyworker in the prison or probation office. As some of the information requested can be disclosed directly, we will be forwarding your request to the relevant business area to take forward and the documents listed will not be included in your SAR response.  
                  <br>
                  <br>Please note, if you have requested medical information as part of the request, responsibility for providing medical information has transferred to the National Health Service / Clinical Commissioning Groups. If you require medical data please contact the Healthcare Services team at the establishment.
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Application Team
                  <br>Data Protection Compliance Team
                  <br>Ministry of Justice
                  </p>
                EOF
                )
    rec.update!(letter_address: <<~EOF
                  #{solictor_receiver}
                  <br>#{address}
                EOF
                )

    rec = LetterTemplate.find_by(abbreviation: 'solicitor-acknowledgement-restricted')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Solicitor acknowledgement letter - RESTRICTED',
                abbreviation: 'solicitor-acknowledgement-restricted',
                template_type: 'acknowledgement',
                body: <<~EOF
                  <p>
                  <% if values.recipient == "requester_recipient" %><br><br>Dear Sirs<% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %> - <%= values.first_prison_number %></strong>
                  <br>
                  <br>Thank you for your subject access request (SAR) dated <%= values.request_dated&.strftime('%e %B %Y') %>.
                  <br>
                  <br>As your client has previously submitted a SAR and have been supplied with information, we will only be providing you with information not previously received, i.e. information from the date of the previous request. The previous request was started on.
                  <br>
                  To complete the SAR we will have to identify information from a number of business areas, including prison establishments. In view of this there is very little information we can provide in response to enquiries. We aim to process your SAR within one calendar month, and it would be helpful if you could limit any communication with the office during this period.
                  <br>
                  Her Majesty’s Prison and Probation Service (HMPPS) holds routine information that can be disclosed to you or your client as part of business as usual requests, without submitting a formal SAR. Please find enclosed a list of documents that can be provided by your client’s keyworker in the prison or probation office. As some of the information requested can be disclosed directly, we will be forwarding your request to the relevant business area to take forward and the documents listed will not be included in your SAR response.
                  <br>
                  Please also note if you have requested medical information as part of the request, the responsibility for providing medical information has transferred to the National Health Service/ Clinical Commissioning Groups. If you require medical information, please contact the Healthcare Services team in the prison.
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Application Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                EOF
                )
    rec.update!(letter_address: <<~EOF
                  #{solictor_receiver}
                  <br>#{address}
                EOF
                )
    rec = LetterTemplate.find_by(abbreviation: 'solicitor-disclosed')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Solicitor disclosed letter',
                abbreviation: 'solicitor-disclosed',
                template_type: 'dispatch',
                body: <<~EOF
                  <p>
                  <br><br><% if values.recipient == "requester_recipient" %>Dear Sirs <% else %>Dear <%= values.recipient_name %> <% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %> - <%= values.first_prison_number %></strong>
                  <br>
                  <br>I am writing in response to your request for information made under the Data Protection Act 2018 (DPA) for the above person.
                  <br>
                  <br>Enclosed is all the information related to your request that I am able to release. Some information may have been withheld and this is because the information is exempt from disclosure under the DPA. The exemptions within the DPA include information which is processed for the prevention or detection of crime or the apprehension or prosecution of offenders, and information that would identify third parties. Where we have withheld exempt information, you will see items redacted on the documents.
                  <br>
                  <br>I can confirm that the personal data contained within these documents is being processed by the MoJ for the purposes of the administration of justice and for the exercise of any functions of the Crown, a Minister of the Crown or a government department. As such we may share or exchange data with other Departments or organisations if it is lawful to do so, for example the Police or the Probation Service.
                  <br>
                  <br>If you have any queries regarding your request please contact the Offender Subject Access Request Team, at the address above. It is also open to you to ask the Information Commissioner to look into the case. You can contact the Information Commissioner at this address:
                  <br>
                  <br>Information Commissioner's Office, Wycliffe House, Water Lane, Wilmslow, Cheshire, SK9 5AF
                  <br>Internet: ico.org.uk
                  <br>
                  <br>Please note that copies of the data provided to you will be retained for no longer than nine months. Once this period has passed, we will be unable to answer any questions you may have or provide duplicates of this information. It will not normally be disclosed in any future SARs.
                  <br>
                  <br>Finally, I would like to suggest that you do not keep this information where it can be accessed by others. It would be helpful to remind your client of this. In a prison establishment the information can be placed in stored property.
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Despatch Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                EOF
                )
    rec.update!(letter_address: <<~EOF
                  #{solictor_receiver}
                  <br>#{address}
                EOF
                )

    rec = LetterTemplate.find_by(abbreviation: 'solicitor-disclosed-covid')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Solicitor disclosed letter (COVID-19)',
                abbreviation: 'solicitor-disclosed-covid',
                template_type: 'dispatch',
                body: <<~EOF
                  <p>
                  <br><br><% if values.recipient == "requester_recipient" %>Dear Sirs <% else %>Dear <%= values.recipient_name %> <% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %> - <%= values.first_prison_number %></strong>
                  <br>
                  <br>I am writing in response to your request for information made under the Data Protection Act 2018 (DPA).
                  <br>
                  <br>During this unprecedented period of our history the Ministry of Justice (MoJ) is continuing to deliver its critical services, with a focus on those areas where resources are immediately required. For this reason and to support our colleagues in Her Majesty's Prison and Probation Service (HMPPS), we are only able to provide you with a copy of the personal information enclosed and not all the information that you requested.
                  <br>
                  <br>Some information may have been withheld because it is exempt from disclosure under the DPA. Where we have withheld exempt information, you will see redactions on the documents. The exemptions for withholding information within the DPA include information which is processed for the prevention or detection of a crime or the apprehension or prosecution of offenders, and information that relates to and would identify third parties.
                  <br>
                  <br>I can confirm that the personal data contained within these documents is being processed by the MoJ for the purposes of the administration of justice and for the exercise of any functions of the Crown, a Minister of the Crown or a government department. As such we may share or exchange personal data with other departments or organisations if it is lawful to do so, for example the police or the probation services.
                  <br>
                  <br>If you have any queries regarding your request please contact the Offender Subject Access Request Team, at the address above. It is also open to you to ask the Information Commissioner to look into the case. You can contact the Information Commissioner at this address: Information Commissioner's Office, Wycliffe House, Water Lane, Wilmslow, Cheshire, SK9 5AF Internet: ico.org.uk
                  <br>
                  <br>Please note that copies of the data provided to you will be retained for no longer than nine months. Once this period has passed, we will be unable to answer any questions you may have or provide duplicates of this information. It will not normally be disclosed in any future SARs. I would like to suggest that you do not keep this information where it can be accessed by others. It would be helpful to remind your client of this. In a prison establishment the information can be placed in stored property.
                  <br>
                  <br>Finally, should you or your client require a copy of any other personal information held by the MoJ we advise you to contact your client’s key worker within the prison who can provide support regarding the disclosure of routine information that does not need to be provided through a formal SAR.
                  <br>
                  <br>After the COVID-19 pandemic or as soon as reasonably practicable (based on Government and Public Health England guidance), we will revert to the provision of full services. We apologise for any inconvenience the reduced but pragmatic service may cause you.
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Despatch Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                EOF
                )
    rec.update!(letter_address: <<~EOF
                  #{solictor_receiver}
                  <br>#{address}
                EOF
                )

    rec = LetterTemplate.find_by(abbreviation: 'complaint-acknowledgement')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Complaint acknowledgement letter',
                abbreviation: 'complaint-acknowledgement',
                template_type: 'acknowledgement',
                body: <<~EOF
                  <p>
                  <% if values.recipient == "requester_recipient" %><br><br>Dear Sirs<% else %><br><br>Dear <%= values.recipient_name %><% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %> - <%= values.first_prison_number %></strong>
                  <br>
                  <br>Thank you for your letter/email dated <%= values.request_dated&.strftime('%e %B %Y') %>.
                  <br>
                  <br>I note the contents and will be looking into your concerns.
                  <br>
                  <br>I will be in contact with you further once I have completed my enquiries. To complete the enquiries I may have to contact other business areas and as such it would be helpful if you could limit any communication with the office during this period.
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>DPA Team Manager
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                EOF
                )
    rec.update!(letter_address: <<~EOF
                  #{solictor_receiver}
                  <br>#{address}
                EOF
                )


    rec = LetterTemplate.find_by(abbreviation: 'despatch-change-of-address')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Change of address',
                abbreviation: 'despatch-change-of-address',
                template_type: 'dispatch',
                body: <<~EOF
                  <p>
                  <br><br><% if values.recipient == "requester_recipient" %>Dear Sirs <% else %>Dear <%= values.recipient_name %> <% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %> - <%= values.first_prison_number %></strong>
                  <br>
                  <br>Your subject access request (SAR) has now been completed.
                  <br>
                  <br>In order to ensure safe receipt of the data can you please confirm the address to which you would like your documents sent.
                  <br>
                  <br>In addition can you also send proof of your identity, a copy of one of the following: 
                  Photograph page of your passport or driving license                  
                  <br>
                  <br><strong>And</strong> a document with your current address on dated within the last six months:
                  <br>Copy of electricity bill
                  <br>Copy of gas bill
                  <br>Copy council tax bill
                  <br>Copy of any other bill in your full name.
                  <br>
                  <br>Once this is received I will ensure that any data is sent to you without delay.
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Despatch Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                EOF
                )
    rec.update!(letter_address: <<~EOF
                  #{solictor_receiver}
                  <br>#{address}
                EOF
                )


    rec = LetterTemplate.find_by(abbreviation: 'despatch-confirming-address')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Confirming address',
                abbreviation: 'despatch-confirming-address',
                template_type: 'dispatch',
                body: <<~EOF
                  <p>
                  <br><br><% if values.recipient == "requester_recipient" %>Dear Sirs <% else %>Dear <%= values.recipient_name %> <% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br>
                  <br>I am writing in response to your request for information made under the Data Protection Act 2018 (DPA). 
                  <% if values.already_late? %>The Ministry of Justice (MoJ) is sorry for the delay in responding to your subject access request (SAR).
                  <% end %>
                  <br>
                  <br>Your SAR is now due to be completed. To ensure safe receipt of the information please can you confirm that you are still residing at this address and provide a copy of one of the following:
                  <br>
                  <br>Photograph page of your passport or driving license
                  <br>
                  <br><strong>And</strong> a document with your current address on dated within the last six months:
                  <br>Copy of electricity bill
                  <br>Copy of gas bill
                  <br>Copy council tax bill
                  <br>Copy of any other bill in your full name.
                  <br>
                  <br>Once this is received your SAR will be completed and despatched to shortly.
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Despatch Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                EOF
                )
    rec.update!(letter_address: <<~EOF
                  #{solictor_receiver}
                  <br>#{address}
                EOF
                )

    rec = LetterTemplate.find_by(abbreviation: 'dispatch-letter-delivery-request-form')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Special/Recorded delivery request',
                abbreviation: 'dispatch-letter-delivery-request-form',
                template_type: 'dispatch',
                base_template_file_ref: 'ims002.docx',
                body: <<~EOF
                  <p>
                  <br><br>Please check following information which will be used in the form.
                  <br>
                  <br><strong>Name:</strong><%=letter.name %>
                  <br><strong>Date:</strong><%=letter.letter_date %>
                  <br><strong>Address:</strong>
                  <br>
                  #{solictor_receiver} - #{address}
                  <br>
                  <br>
                  <br>Despatch Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                EOF
                )
    rec.update!(letter_address: <<~EOF
                  #{solictor_receiver}
                  <br>#{address}
                EOF
                )

    # Letters below are commented out due to not being required at the present time 2/08/2021
    # --------------
    #
    #rec = LetterTemplate.find_by(abbreviation: 'prisoner-acknowledgement-covid')
    #rec = LetterTemplate.new if rec.nil?
    #rec.update!(name: 'Prisoner acknowledgement letter (COVID-19)',
    #            abbreviation: 'prisoner-acknowledgement-covid',
    #            template_type: 'acknowledgement',
    #            body: <<~EOF
    #              <p>
    #              <br><br>Dear <%= values.requester_name %>
    #              <br>
    #              <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
    #              <br>
    #              <br>Thank you for your Subject Access Request (SAR) dated <%= values.request_dated&.strftime('%e %B %Y') %>.
    #              <br>
    #              <br>We are not currently able to respond to SARs in full due to coronavirus COVID-19 disruption. During this unprecedented period of our history the Ministry of Justice (MoJ) is continuing to deliver its critical services, with a focus on those areas where resources are immediately required. For this reason and to support our colleagues in Her Majesty's Prison and Probation Service (HMPPS), we are only able to provide you with a copy of the personal information held on the PNOMIS electronic system.
    #              <br>
    #              <br>Should you require a copy of any other personal information held by the MoJ we advise you to contact your key worker within the prison who can provide support regarding the disclosure of routine information that does not need to be provided through a formal SAR.
    #              <br>
    #              <br>After the COVID-19 pandemic or as soon as reasonably practicable (based on Government and Public Health England guidance), we will revert to the provision of full services. We apologise for any inconvenience the reduced but pragmatic service may cause you.
    #              <br>
    #              <br>Yours sincerely
    #              <br>
    #              <br>
    #              <br>
    #              <br>
    #              <br>Application Team
    #              <br>Data Protection Compliance Team
    #              <br>Ministry of Justice
    #              </p>
    #            EOF
    #            )
    #rec.update!(letter_address: <<~EOF
    #              #{prison_receiver}
    #              <br>#{address}
    #            EOF
    #            )
    #
    #
    #rec = LetterTemplate.find_by(abbreviation: 'solicitor-acknowledgement-covid')
    #rec = LetterTemplate.new if rec.nil?
    #rec.update!(name: 'Solicitor acknowledgement letter (COVID-19)',
    #            abbreviation: 'solicitor-acknowledgement-covid',
    #            template_type: 'acknowledgement',
    #            body: <<~EOF
    #              <p>
    #              <% if values.recipient == "requester_recipient" %><br><br>Dear Sirs<% end %>
    #              <br>
    #              <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
    #              <br><strong><%= values.subject_full_name&.upcase %> - <%= values.first_prison_number %></strong>
    #              <br>
    #              <br>Thank you for your subject access request (SAR) dated <%= values.request_dated&.strftime('%e %B %Y') %>.
    #              <br>
    #              <br>We are not currently able to respond to SARs in full due to coronavirus COVID-19 disruption. During this unprecedented period of our history the Ministry of Justice (MoJ) is continuing to deliver its critical services, with a focus on those areas where resources are immediately required. For this reason and to support our colleagues in Her Majesty's Prison and Probation Service (HMPPS), we are only able to provide you with a copy of the personal information held on the PNOMIS electronic system.
    #              <br>
    #              <br>Should you or your client require a copy of any other personal information held by the MoJ we advise you to contact your client’s key worker within the prison who can provide support regarding the disclosure of routine information that does not need to be provided through a formal SAR.
    #              <br>
    #              <br>After the COVID-19 pandemic or as soon as reasonably practicable (based on Government and Public Health England guidance), we will revert to the provision of full services. We apologise for any inconvenience the reduced but pragmatic service may cause you.
    #              <br>
    #              <br>Yours sincerely
    #              <br>
    #              <br>
    #              <br>
    #              <br>
    #              <br>Application Team
    #              <br>Data Protection Compliance Team
    #              <br>Ministry of Justice
    #              </p>
    #            EOF
    #            )
    #rec.update!(letter_address: <<~EOF
    #              #{solictor_receiver}
    #              <br>#{address}
    #            EOF
    #            )
    #
  end
end
#rubocop:enable Lint/RedundantCopDisableDirective, Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/MethodLength
