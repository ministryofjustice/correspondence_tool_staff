class LetterTemplateSeeder
  def seed!
    puts "----Seeding Letter Templates----"

    rec = LetterTemplate.find_by(abbreviation: 'solicitor-acknowledgement')
    rec = LetterTemplate.new if rec.nil?
    rec.update!(name: 'Solicitor acknowledgement letter',
                abbreviation: 'solicitor-acknowledgement',
                template_type: 'acknowledgement',
                body: <<~EOF
                  <%= values.name %>
                  <%= values.third_party_company_name %>
                  <%= values.postal_address %>

                  Your Reference: <%= values.third_party_reference %>

                  Our Reference:  DPA <%= values.number %>

                  Date: <%= Date.today.strftime('%e %b %Y') %>

                  DATA PROTECTION ACT 2018:  SUBJECT ACCESS REQUEST
                  <%= values.subject_full_name&.upcase %>-<%= values.prison_number&.upcase%>

                  Dear Sirs

                  Thank you for your subject access request (SAR) dated <%= values.received_date.strftime('%e %b %Y') %>.

                  Please note that as your client has previously submitted a SAR and has been supplied with data, we will only be providing you with data not previously received, i.e. data from the date of the previous request. The previous request was started on [INSERT DATE PREVIOUS REQUEST RECEIVED].

                  To complete the SAR, we will have to identify information from a number of business areas, including establishments. Because of this, there is very little information we can provide in response to enquiries. It would be helpful if you could limit correspondence during this period.

                  Please note, if you have requested medical information as part of the request, responsibility for providing medical information has transferred to the National Health Service / Clinical Commissioning Groups. If you require medical data please contact the Healthcare Services team at the establishment.

                  Yours sincerely


                  Application Team
                  Data Protection Compliance Team
                  Ministry of Justice
                EOF
                )
  end
end
