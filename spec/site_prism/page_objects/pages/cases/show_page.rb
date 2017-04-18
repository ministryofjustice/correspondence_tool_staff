module PageObjects
  module Pages
    module Cases
      class ShowPage < SitePrism::Page
        set_url '/cases/{id}'
        # TODO: the sections here ... actually this whole page, can show up in other
        #       locations (cases/assignments/edit, cases/assignments/show_rejected)
        #       so we should be moving most/all of this into separate section files
        #       for inclusion into those pages.

        element :message, '.request'
        element :received_date, '.request--date-received'
        element :escalation_notice, '.alert-orange'

        section :sidebar, 'section.case-sidebar' do
          element :external_deadline, '.external_deadline .case-sidebar__data'
          element :status, '.status .case-sidebar__data'
          element :who_its_with, '.who-its-with .case-sidebar__data'
          element :name, '.name .case-sidebar__data'
          element :requester_type, '.case-sidebar__data--contact .requester-type'
          element :email, '.case-sidebar__data--contact .email'
          element :postal_address, '.case-sidebar__data--contact .postal-address'
          section :actions, '.actions .case-sidebar__data' do
            element :upload_response, '#action--upload-response'
            element :mark_as_sent, '#action--mark-response-as-sent'
            element :close_case, '#action--close-case'
          end
        end

        section :case_heading, '.case-heading' do
          element :case_number, '.case-heading--secondary'
        end

        section :response_details, '.request--response-details' do
          sections :responses,
                   PageObjects::Sections::ResponseAttachmentSection,
                   '#request--responses tr'

          element :responding_team, '#request--responding-team'
          element :responders, '#request--responders'
          element :date_responded, '#request--date-responded'
          element :timeliness, '#request--response-timeliness'
          element :time_taken, '#request--response-time-taken'
          element :outcome, '#request--outcome'
          element :reason_for_refusal, '#request--reason-for-refusal'
          element :exemptions, '#request--exemptions'
        end
      end
    end
  end
end
