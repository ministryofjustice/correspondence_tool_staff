class LetterTemplateSeeder
  #rubocop:disable Metrics/MethodLength
  def seed!
    puts "----Seeding Letter Templates----"

    rec = LetterTemplate.find_by(abbreviation: 'solicitor-acknowledgement')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Solicitor acknowledgement letter',
                abbreviation: 'solicitor-acknowledgement',
                template_type: 'acknowledgement',
                body: <<~EOF
                  <p><strong>DATA PROTECTION ACT 2018:  SUBJECT ACCESS REQUEST
                  <br><%= values.subject_full_name&.upcase %>-<%= values.prison_number&.upcase %></strong>
                  <br>
                  <br>Dear Sirs
                  <br>
                  <br>Thank you for your subject access request (SAR) dated <%= 'XXXXXXX' %><%# TODO values.request_dated.strftime('%e %b %Y') %>.
                  <br>
                  <br>Please note that as your client has previously submitted a SAR and has been supplied with data, we will only be providing you with data not previously received, i.e. data from the date of the previous request. The previous request was started on [INSERT DATE PREVIOUS REQUEST RECEIVED].
                  <br>
                  <br>To complete the SAR, we will have to identify information from a number of business areas, including establishments. <strong>Because of this, there is very little information we can provide in response to enquiries. It would be helpful if you could limit correspondence during this period.</strong>
                  <br>
                  <br>Please note, if you have requested medical information as part of the request, responsibility for providing medical information has transferred to the National Health Service / Clinical Commissioning Groups. If you require medical data please contact the Healthcare Services team at the establishment.
                  </p>
                EOF
                )

    rec = LetterTemplate.find_by(abbreviation: 'solicitor-acknowledgement-covid')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Solicitor acknowledgement letter (COVID-19)',
                abbreviation: 'solicitor-acknowledgement-covid',
                template_type: 'acknowledgement',
                body: <<~EOF
                  <p><strong>DATA PROTECTION ACT 2018:  SUBJECT ACCESS REQUEST
                  <br><%= values.subject_full_name&.upcase %>-<%= values.prison_number&.upcase %></strong>
                  <br>
                  <br>Dear Sirs
                  <br>
                  <br>Thank you for your subject access request (SAR) dated <%= 'XXXXXXX' %><%# TODO values.request_dated.strftime('%e %b %Y') %>.
                  <br>
                  <br>We are not currently able to respond to SARs in full due to coronavirus COVID-19 disruption. During this unprecedented period of our history the Ministry of Justice (MoJ) is continuing to deliver its critical services, with a focus on those areas where resources are immediately required. For this reason and to support our colleagues in Her Majesty’s Prison and Probation Service (HMPPS), we are only able to provide you with a copy of the personal information held on the PNOMIS electronic system.
                  <br>
                  <br>Should you require a copy of any other personal information held by the MoJ, we invite you to submit a new SAR once the COVID-19 pandemic is over. Unfortunately, we are unable to advise when this will be at present.
                  </p>
                EOF
                )

    rec = LetterTemplate.find_by(abbreviation: 'prisoner-acknowledgement-covid')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Prisoner acknowledgement letter (COVID-19)',
                abbreviation: 'prisoner-acknowledgement-covid',
                template_type: 'acknowledgement',
                body: <<~EOF
                  <p><strong>DATA PROTECTION ACT 2018:  SUBJECT ACCESS REQUEST</strong>
                  <br>
                  <br>Thank you for your Subject Access Request (SAR) dated <%= 'XXXXXXX' %><%# TODO values.request_dated.strftime('%e %b %Y') %>.
                  <br>
                  <br>We are not currently able to respond to SARs in full due to coronavirus COVID-19 disruption. During this unprecedented period of our history the Ministry of Justice (MoJ) is continuing to deliver its critical services, with a focus on those areas where resources are immediately required. For this reason and to support our colleagues in Her Majesty’s Prison and Probation Service (HMPPS), we are only able to provide you with a copy of the personal information held on the PNOMIS electronic system.
                  <br>
                  <br>Should you require a copy of any other personal information held by the MoJ, we invite you to submit a new SAR once the COVID-19 pandemic is over. Unfortunately, we are unable to advise when this will be at present. You can also request the disclosure of routine information that does not need to be provided through a formal SAR from your keyworker in the prison.
                  </p>
                EOF
                )

    rec = LetterTemplate.find_by(abbreviation: 'solicitor-disclosed')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Solicitor disclosed letter',
                abbreviation: 'solicitor-disclosed',
                template_type: 'dispatch',
                body: <<~EOF
                  <p><strong>DATA PROTECTION ACT 2018:  SUBJECT ACCESS REQUEST
                  <br><%= values.subject_full_name&.upcase %>-<%= values.prison_number&.upcase %></strong>
                  <br>
                  <br>I am writing in response to your request for information made under the Data Protection Act 1998 (DPA) for the above person. The Ministry of Justice (MoJ) is sorry for the delay in responding to your subject access request (SAR).
                  <br>
                  <br>Enclosed is all the information related to your request that I am able to release. Some information may have been withheld and this is because the information is exempt from disclosure under the DPA. The exemptions within the DPA include information which is processed for the prevention or detection of crime or the apprehension or prosecution of offenders, and information that would identify third parties. Where we have withheld exempt information, you will see items redacted on the documents.
                  <br>
                  <br>I can confirm that the personal data contained within these documents is being processed by the MoJ for the purposes of the administration of justice and for the exercise of any functions of the Crown, a Minister of the Crown or a government department. As such we may share or exchange data with other Departments or organisations if it is lawful to do so, for example the Police or the Probation Service.
                  <br>
                  <br>If you have any queries regarding your request please contact the Data Protection Compliance Team (DPCT), at the address above. It is also open to you to ask the Information Commissioner to look into the case. You can contact the Information Commissioner at this address:
                  <br>
                  <br>Information Commissioner’s Office, Wycliffe House, Water Lane, Wilmslow, Cheshire, SK9 5AF
                  <br>Internet: www.ico.gov.uk
                  <br>
                  <br>Please note that copies of the data provided to you will be retained for no longer than nine months. Once this period has passed, we will be unable to answer any questions you may have or provide duplicates of this information. It will not normally be disclosed in any futures SARs.
                  <br>
                  <br>I would like to suggest that you do not keep this information where it can be accessed by others. It would be helpful to remind your client of this. In a prison establishment the information can be placed in stored property.
                  <br>
                  <br>Finally, the MoJ is sorry that your SAR was not completed within 40 days. We take our obligations under the DPA very seriously and we make every effort to complete all SARs by the statutory deadline but regrettably there are occasions when we are unable to achieve this.
                  </p>
                EOF
                )
  end
  #rubocop:enable Metrics/MethodLength
end
