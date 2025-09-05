class LetterTemplateSeeder
  def seed!
    Rails.logger.debug "---- Seeding Letter Templates ----"
    intial_letters_seed
  end

  def intial_letters_seed
    prison_receiver = prison_receiver_string
    solictor_receiver = solictor_receiver_string
    address = address_string

    rec = LetterTemplate.find_by(abbreviation: "prisoner-acknowledgement")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Prisoner acknowledgement letter",
                abbreviation: "prisoner-acknowledgement",
                template_type: "acknowledgement",
                base_template_file_ref: "ims001.docx",
                body: <<~BODY,
                  <p>
                  <br><br>Dear <%= values.requester_name %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br>
                  <br>Thank you for your Subject Access Request (SAR) dated <%= values.request_dated&.strftime('%e %B %Y') %>.
                  <br>
                  <br>To complete the SAR we will have to identify information from a number of business areas, including prison establishments. In view of this there is very little information we can provide in response to enquiries. We aim to process your SAR within one calendar month, and it would be helpful if you could limit any communication with the office during this period.#{'   '}
                  <br>
                  <br>Please also note if you have requested medical information as part of the request, the responsibility for providing medical information has transferred to the National Health Service/ Clinical Commissioning Groups. If you require medical information, please contact the Healthcare Services team in the prison.
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
                BODY
               )
    rec.update!(letter_address: <<~BODY,
      <p>
      #{prison_receiver}<br>
      #{address}
      </p>
    BODY
               )

    rec = LetterTemplate.find_by(abbreviation: "prisoner-acknowledgement-restricted")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Prisoner acknowledgement letter - RESTRICTED SAR",
                abbreviation: "prisoner-acknowledgement-restricted",
                template_type: "acknowledgement",
                base_template_file_ref: "ims001.docx",
                body: <<~BODY,
                  <p>
                  <br><br>Dear <%= values.requester_name %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br>
                  <br>Thank you for your Subject Access Request (SAR) dated <%= values.request_dated&.strftime('%e %B %Y') %>.
                  <br>
                  <br>As you have previously submitted a SAR and have been supplied with information, we will only be providing you with information not previously received, i.e. information from the date of the previous request. The previous request was started on [INSERT DATE PREVIOUS REQUEST RECEIVED].
                  <br>
                  <br>To complete the SAR we will have to identify information from a number of business areas, including prison establishments. In view of this there is very little information we can provide in response to enquiries. We aim to process your SAR within one calendar month, and it would be helpful if you could limit any communication with the office during this period.
                  <br>
                  <br>Please also note if you have requested medical information as part of the request, the responsibility for providing medical information has transferred to the National Health Service / Clinical Commissioning Groups. If you require medical information, please contact the Healthcare Services team in the prison.
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
                BODY
               )
    rec.update!(letter_address: <<~BODY,
      <p>
      #{prison_receiver}<br>
      #{address}
      </p>
    BODY
               )

    rec = LetterTemplate.find_by(abbreviation: "prisoner-disclosed-cover-letter")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Prisoner disclosed cover letter",
                abbreviation: "prisoner-disclosed-cover-letter",
                template_type: "dispatch",
                body: <<~BODY,
                  <p>
                  <br><br>Dear Colleague
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %><% if values.prison_number.present? %> - <%= values.first_prison_number %><% end %></strong>
                  <br>
                  <br>Please find enclosed documents relating to a Subject Access Request (SAR) made under the Data Protection Act 2018 by the above offender.
                  <br>
                  <br><strong>This letter must not be seen by the offender. Once the parcel has been passed to the offender please ensure this covering letter is destroyed securely.</strong>
                  <br>
                  <br>Following inappropriate articles being found in official correspondence and subsequent security alert email issued on 5 March 2015; if you are suspicious about the content of this parcel it should be opened in the presence of the offender, contents checked and passed to them immediately.
                  <br>
                  <br>If you have any queries relating to these instructions or concerns regarding the parcel please contact our team immediately on 01283 496 110. Do not deliver the SAR to the offender or forward the parcel on to another prison. Alternatively, you can return the SAR to our team at the address above with a covering letter outlining your concerns.
                  <br>
                  <br>Thank you for your assistance in this matter.
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Business Support Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                BODY
               )
    rec.update!(letter_address: <<~BODY,
      <p>
      Business Hub<br>
      <%= letter.format_address(values.subject_address).gsub("\n", "<br>").html_safe %>
      </p>
    BODY
               )

    rec = LetterTemplate.find_by(abbreviation: "prisoner-disclosed")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Prisoner disclosed letter",
                abbreviation: "prisoner-disclosed",
                template_type: "dispatch",
                body: <<~BODY,
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
                  <br>Information Commissioner&apos;s Office, Wycliffe House, Water Lane, Wilmslow, Cheshire, SK9 5AF
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
                  <br>Business Support Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                BODY
               )
    rec.update!(letter_address: <<~ADDRESS,
      <p>
      #{prison_receiver}<br>
      #{address}
      </p>
    ADDRESS
               )

    rec = LetterTemplate.find_by(abbreviation: "solicitor-acknowledgement")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Solicitor acknowledgement letter",
                abbreviation: "solicitor-acknowledgement",
                template_type: "acknowledgement",
                base_template_file_ref: "ims001.docx",
                body: <<~BODY,
                  <p>
                  <br><br>Dear <%= values.requester_name %>
                  <% if values.recipient == "requester_recipient" %><br><br>Dear Sirs<% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %><% if values.prison_number.present? %> - <%= values.first_prison_number %><% end %></strong>
                  <br>
                  <br>Thank you for your subject access request (SAR) dated <%= values.request_dated&.strftime('%e %B %Y') %>.
                  <br>
                  <br>To complete the SAR we will have to identify information from a number of business areas, including prison establishments. In view of this there is very little information we can provide in response to enquiries. We aim to process your SAR within one calendar month, and it would be helpful if you could limit any communication with the office during this period.#{' '}
                  <br>
                  <br>Please note, if you have requested medical information as part of the request, responsibility for providing medical information has transferred to the National Health Service / Clinical Commissioning Groups. If you require medical data please contact the Healthcare Services team at the establishment.
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
                BODY
               )
    rec.update!(letter_address: <<~ADDRESS,
      <p>
      #{solictor_receiver}<br>
      #{address}
      </p>
    ADDRESS
               )

    rec = LetterTemplate.find_by(abbreviation: "solicitor-acknowledgement-restricted")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Solicitor acknowledgement letter - RESTRICTED SAR",
                abbreviation: "solicitor-acknowledgement-restricted",
                template_type: "acknowledgement",
                base_template_file_ref: "ims001.docx",
                body: <<~BODY,
                  <p>
                  <br><br>Dear <%= values.requester_name %>
                  <% if values.recipient == "requester_recipient" %><br><br>Dear Sirs<% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %><% if values.prison_number.present? %> - <%= values.first_prison_number %><% end %></strong>
                  <br>
                  <br>Thank you for your subject access request (SAR) dated <%= values.request_dated&.strftime('%e %B %Y') %>.
                  <br>
                  <br>As your client has previously submitted a SAR and have been supplied with information, we will only be providing you with information not previously received, i.e. information from the date of the previous request. The previous request was started on [INSERT DATE PREVIOUS REQUEST RECEIVED].
                  <br>
                  <br>To complete the SAR we will have to identify information from a number of business areas, including prison establishments. In view of this there is very little information we can provide in response to enquiries. We aim to process your SAR within one calendar month, and it would be helpful if you could limit any communication with the office during this period.
                  <br>
                  <br>Please also note if you have requested medical information as part of the request, the responsibility for providing medical information has transferred to the National Health Service/ Clinical Commissioning Groups. If you require medical information, please contact the Healthcare Services team in the prison.
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
                BODY
               )
    rec.update!(letter_address: <<~ADDRESS,
      <p>
      #{solictor_receiver}<br>
      #{address}
      </p>
    ADDRESS
               )

    rec = LetterTemplate.find_by(abbreviation: "solicitor-disclosed")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Solicitor disclosed letter",
                abbreviation: "solicitor-disclosed",
                template_type: "dispatch",
                body: <<~BODY,
                  <p>
                  <br><br><% if values.recipient == "requester_recipient" %>Dear Sirs <% else %>Dear <%= values.recipient_name %> <% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %><% if values.prison_number.present? %> - <%= values.first_prison_number %><% end %></strong>
                  <br>
                  <br>I am writing in response to your request for information made under the Data Protection Act 2018 (DPA) for the above person.
                  <br>
                  <br>Enclosed is all the information related to your request that I am able to release. Some information may have been withheld and this is because the information is exempt from disclosure under the DPA. The exemptions within the DPA include information which is processed for the prevention or detection of crime or the apprehension or prosecution of offenders, and information that would identify third parties. Where we have withheld exempt information, you will see items redacted on the documents.
                  <br>
                  <br>I can confirm that the personal data contained within these documents is being processed by the MoJ for the purposes of the administration of justice and for the exercise of any functions of the Crown, a Minister of the Crown or a government department. As such we may share or exchange data with other Departments or organisations if it is lawful to do so, for example the Police or the Probation Service.
                  <br>
                  <br>If you have any queries regarding your request please contact the Offender Subject Access Request Team, at the address above. It is also open to you to ask the Information Commissioner to look into the case. You can contact the Information Commissioner at this address:
                  <br>
                  <br>Information Commissioner&apos;s Office, Wycliffe House, Water Lane, Wilmslow, Cheshire, SK9 5AF
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
                  <br>Business Support Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                BODY
               )
    rec.update!(letter_address: <<~ADDRESS,
      <p>
      #{solictor_receiver}<br>
      #{address}
      </p>
    ADDRESS
               )

    rec = LetterTemplate.find_by(abbreviation: "complaint-acknowledgement")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Complaint acknowledgement letter",
                abbreviation: "complaint-acknowledgement",
                template_type: "acknowledgement",
                body: <<~BODY,
                  <p>
                  <% if values.recipient == "requester_recipient" %><br><br>Dear Sirs<% else %><br><br>Dear <%= values.recipient_name %><% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %><% if values.prison_number.present? %> - <%= values.first_prison_number %><% end %></strong>
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
                BODY
               )
    rec.update!(letter_address: <<~ADDRESS,
      <p>
      #{solictor_receiver}<br>
      #{address}
      </p>
    ADDRESS
               )

    rec = LetterTemplate.find_by(abbreviation: "despatch-change-of-address")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Change of address",
                abbreviation: "despatch-change-of-address",
                template_type: "dispatch",
                body: <<~BODY,
                  <p>
                  <br><br><% if values.recipient == "requester_recipient" %>Dear Sirs <% else %>Dear <%= values.recipient_name %> <% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %><% if values.prison_number.present? %> - <%= values.first_prison_number %><% end %></strong>
                  <br>
                  <br>Your subject access request (SAR) has now been completed.
                  <br>
                  <br>In order to ensure safe receipt of the data can you please confirm the address to which you would like your documents sent.
                  <br>
                  <br>In addition can you also send proof of your identity, a copy of one of the following:#{' '}
                  Photograph page of your passport or driving license#{'                  '}
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
                  <br>Business Support Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                BODY
               )
    rec.update!(letter_address: <<~ADDRESS,
      <p>
      #{solictor_receiver}<br>
      #{address}
      </p>
    ADDRESS
               )

    rec = LetterTemplate.find_by(abbreviation: "dispatch-letter-delivery-request-form")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Special/Recorded delivery request",
                abbreviation: "dispatch-letter-delivery-request-form",
                template_type: "dispatch",
                base_template_file_ref: "ims002.docx",
                body: <<~BODY,
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
                  <br>Business Support Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                BODY
               )
    rec.update!(letter_address: <<~ADDRESS,
      <p>
      #{solictor_receiver}<br>
      #{address}
      </p>
    ADDRESS
               )

    rec = LetterTemplate.find_by(abbreviation: "complaint-inaccurate-data")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Complaint: Inaccurate data",
                abbreviation: "complaint-inaccurate-data",
                template_type: "dispatch",
                body: <<~BODY,
                  <p>
                  <br><br><% if values.recipient == "requester_recipient" %>Dear Sirs <% else %>Dear <%= values.recipient_name %> <% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br>
                  <br>Thank you for your letter/email dated <%= values.request_dated&.strftime('%e %B %Y') %>.
                  <br>
                  <br>I note the contents and I have asked His Majesty&apos;s Prison and Probation Service to look into the matter and advise you further.
                  <br>
                  <br><strong>Your letter/email has been sent on to: [INSERT APPROPRIATE ADDRESS]</strong>
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
                BODY
               )
    rec.update!(letter_address: <<~ADDRESS,
      <p>
      #{solictor_receiver}<br>
      #{address}
      </p>
    ADDRESS
               )

    rec = LetterTemplate.find_by(abbreviation: "complaint-no-further-data")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Complaint: No further data",
                abbreviation: "complaint-no-further-data",
                template_type: "dispatch",
                body: <<~BODY,
                  <p>
                  <br><br><% if values.recipient == "requester_recipient" %>Dear Sirs <% else %>Dear <%= values.recipient_name %> <% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br><strong><%= values.subject_full_name&.upcase %></strong>
                  <br>
                  <br>Thank you for your letter/email dated <%= values.request_dated&.strftime('%e %B %Y') %>.
                  <br>
                  <br>I have reviewed your concerns and I can confirm that you have received all the information related to your request that I am able to release.
                  <br>
                  <br>As previously advised some information may have been withheld and this is because the information is exempt from disclosure under the DPA. The exemptions within the DPA include information which is processed for the prevention or detection of a crime or the apprehension or prosecution of offenders, and information that would identify third parties. Where we have withheld exempt information, you will see items redacted on the documents.
                  <br>
                  <br>It is also open to you to ask the Information Commissioner to look into the case. You can contact the Information Commissioner at this address:
                  <br>Information Commissioner&apos;s Office, Wycliffe House, Water Lane, Wilmslow,
                  <br>Cheshire, SK9 5AF
                  <br>Internet: <a href="www.ico.gov.uk">www.ico.gov.uk</a>
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
                BODY
               )
    rec.update!(letter_address: <<~ADDRESS,
      <p>
      #{solictor_receiver}<br>
      #{address}
      </p>
    ADDRESS
               )

    rec = LetterTemplate.find_by(abbreviation: "complaint-additional-data")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Complaint: Additional data enclosed",
                abbreviation: "complaint-additional-data",
                template_type: "dispatch",
                body: <<~BODY,
                  <p>
                  <br><br><% if values.recipient == "requester_recipient" %>Dear Sirs <% else %>Dear <%= values.recipient_name %> <% end %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br>
                  <br>Thank you for your letter/email dated <%= values.request_dated&.strftime('%e %B %Y') %>.
                  <br>
                  <br>I have reviewed your concerns and am able to provide some further information to you.
                  <br>
                  <br>Enclosed is all the information related to your request that I am able to release. Some information may have been withheld and this is because the information is exempt from disclosure under the DPA. The exemptions within the DPA include information which is processed for the prevention or detection of crime or the apprehension or prosecution of offenders, and information that would identify third parties. Where we have withheld exempt information, you will see items redacted on the documents.
                  <br>
                  <br>I can confirm that the personal data contained within these documents is being processed by the Ministry of Justice for the purposes of the administration of justice and for the exercise of any functions of the Crown, a Minister of the Crown or a government department. As such we may share or exchange data with other Departments or organisations if it is lawful to do so, for example the Police or the Probation Service.
                  <br>
                  <br>If you have any queries regarding your request please contact the Data Protection Compliance Team (DPCT), at the address above. It is also open to you to ask the Information Commissioner to look into the case. You can contact the Information Commissioner at this address:
                  <br>Information Commissioner&apos;s Office, Wycliffe House, Water Lane, Wilmslow,
                  <br>Cheshire, SK9 5AF
                  <br>Internet: <a href="www.ico.gov.uk">www.ico.gov.uk</a>
                  <br>
                  <br>Please note that copies of the data provided to you will be retained for no longer than nine months. Once this period has passed, we will be unable to answer any questions you may have or provide duplicates of this information. It will not normally be disclosed in any futures SARs.
                  <br>
                  <br>Finally I would like to suggest that you do not keep this information where it can be accessed by others. It would be helpful to remind your client of this.
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
                BODY
               )
    rec.update!(letter_address: <<~ADDRESS,
      <p>
      #{solictor_receiver}<br>
      #{address}
      </p>
    ADDRESS
               )

    rec = LetterTemplate.find_by(abbreviation: "digital-dispatch-solicitor-letter")
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: "Digital dispatch solicitor letter",
                abbreviation: "digital-dispatch-solicitor-letter",
                template_type: "dispatch",
                body: <<~BODY,
                  <p>
                  <br>
                  <br>Dear <%= values.recipient_name %>
                  <br>
                  <br><strong>DATA PROTECTION ACT 2018: SUBJECT ACCESS REQUEST</strong>
                  <br>
                  <br><strong><%= values.subject_full_name&.upcase %><% if values.prison_number.present? %> - <%= values.first_prison_number %><% end %></strong>
                  <br>
                  <br>I am writing in response to your request for information made under the Data Protection Act 2018 (DPA) for the above person.
                  <br>
                  <br>We have now completed your Subject Access Request (SAR), and the requested information has been provided to you digitally within this folder. <strong>Please note that the link will expire 30 days from the date of issue</strong>, and it is recommended to download this information as soon as possible.
                  <br>
                  <br>Provided is all the information related to your request that I am able to release. Some information may have been withheld, and this is because the information is exempt from disclosure under the DPA. The exemptions within the DPA include information which is processed for the prevention or detection of crime or the apprehension or prosecution of offenders, and information that would identify third parties. Where we have withheld exempt information, you will see items redacted on the documents.
                  <br>
                  <br>I can confirm that the personal data contained within these documents is being processed by the MoJ for the purposes of the administration of justice and for the exercise of any functions of the Crown, a Minister of the Crown or a government department. As such we may share or exchange data with other Departments or organisations if it is lawful to do so, for example the Police or the Probation Service.
                  <br>
                  <br>If you have any queries regarding your request please contact the Offender Subject Access Request Team, at the address above. It is also open to you to ask the Information Commissioner to look into the case. You can contact the Information Commissioner at this address:
                  <br>
                  <br>Information Commissioner&apos;s Office, Wycliffe House, Water Lane, Wilmslow, Cheshire, SK9 5AF
                  <br>Internet: <a href="www.ico.gov.uk">www.ico.gov.uk</a>
                  <br>
                  <br>Please note that copies of the data provided to you will be retained for no longer than nine months. Once this period has passed, we will be unable to answer any questions you may have or provide duplicates of this information. It will not normally be disclosed in any future SARs.
                  <br>
                  <br>Finally, as the information contains personal data, it requires secure and responsible handling. It is strongly advised to:
                  <br>
                  <br> &#8226; Refrain from forwarding or sharing the link with unauthorised persons.
                  <br> &#8226; Access the information in a secure environment using a trusted device.
                  <br> &#8226; Store the link securely and only for as long as necessary.
                  <br> &#8226; Delete the link once the data has been accessed or saved securely.
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Yours sincerely
                  <br>
                  <br>
                  <br>
                  <br>
                  <br>Business Support Team
                  <br>Offender Subject Access Request Team
                  <br>Ministry of Justice
                  </p>
                BODY
               )
    rec.update!(letter_address: <<~ADDRESS,
      <p>
      #{solictor_receiver}<br>
      #{address}
      </p>
    ADDRESS
               )
  end

private

  def prison_receiver_string
    <<~STRING
      <%= letter.name %><% if values.prison_number.present? %> - <%= values.first_prison_number %><% end %>
    STRING
  end

  def solictor_receiver_string
    <<~STRING
      <% if letter.name.present? %><%= letter.name %><% end %>
      <br>
      <% if values.third_party_company_name.present? %><%= values.third_party_company_name %><% end %>
    STRING
  end

  def address_string
    <<~STRING
      <%= letter.address.gsub("\n", "<br>").html_safe %>
    STRING
  end
end
