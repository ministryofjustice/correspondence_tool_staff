module PageObjects
  module Sections
    module Cases
      module OffenderSAR
        class CaseDetailsSection < SitePrism::Section

        element :section_heading, '.case-details .request--heading'
        element :original_section_heading,
                '.original-case-details .request--heading'

        section :sar_basic_details, '.sar-basic-details' do
          section :case_type, 'tr.case-type' do
            element :sar_trigger, 'td .sar-trigger'
            element :data, 'td:first'
          end

          section :data_subject, 'tr.data-subject' do
            element :data, 'td'
          end

          section :data_subject_type, 'tr.data-subject-type' do
            element :data, 'td'
          end

          section :third_party, 'tr.third-party' do
            element :data, 'td:first'
          end

          section :third_party_name, 'tr.third-party-name' do
            element :data, 'td:first'
          end

          section :requester_reference, 'tr.external-reference' do
            element :data, 'td'
          end

          section :third_party_company_name, 'tr.third-party-company-name' do
            element :data, 'td'
          end

          section :prison_number, 'tr.prison-number' do
            element :data, 'td'
          end

          section :subject_aliases, 'tr.subject-aliases' do
            element :data, 'td'
          end

          section :previous_case_numbers, 'tr.previous-case-numbers' do
            element :data, 'td'
          end

          section :other_subject_ids, 'tr.other-subject-ids' do
            element :data, 'td'
          end

          section :case_reference_number, 'tr.case-reference-number' do
            element :data, 'td'
          end

          section :subject_address, 'tr.subject-address' do
            element :data, 'td'
          end
          
          section :request_method, 'tr.request-method' do
            element :data, 'td'
          end
          
          section :date_received, 'tr.date-received' do
            element :data, 'td:first'
          end

          section :request_dated, 'tr.request_dated' do
            element :data, 'td:first'
          end

          section :requester_reference, 'tr.requester-reference' do
            element :data, 'td'
          end

          section :date_of_birth, 'tr.date-of-birth' do
            element :data, 'td'
          end

          section :internal_deadline, 'tr.case-internal-deadline' do
            element :data, 'td:nth-child(2)'
          end

          section :external_deadline, 'tr.case-external-deadline' do
            element :data, 'td:nth-child(2)'
          end

          section :response_address, 'tr.response-address' do
            element :data, 'td'
          end

          section :team,  'tr.team' do
            element :data, 'td'
          end
        end

        section :responders_details, '.responder-details' do
          section :team, '.team' do
            element :data, 'td:nth-child(2)'
          end

          section :name, '.responder-name' do
            element :data, 'td:nth-child(2)'
          end
        end

        section :compliance_details, '.compliance-details' do
          section :compliance_date, '.compliance-date' do
            element :data, 'td'
          end

          section :compliant_timeliness, '.compliant-timeliness' do
            element :data, 'td'
          end
        end

        section :response_details, '.response-details' do

          section :date_responded, '.date-responded' do
            element :data, 'td'
          end

          section :timeliness, '.timeliness' do
            element :data, 'td'
          end

          section :late_team, '.late-team' do
            element :data, 'td'
          end

          section :time_taken, '.time-taken' do
            element :data, 'td:nth-child(2)'
          end

          section :info_held, '.info-held' do
            element :data, 'td'
          end
          section :outcome, '.outcome' do
            element :data, 'td'
          end

          section :refusal_reason, '.refusal-reason' do
            element :data, 'td'
          end

          section :exemptions, '.exemptions' do
            elements :list, 'td ul li'
          end
        end



        element :edit_case, :xpath, '//a[contains(.,"Edit case details")]'
        element :edit_case_link, :xpath, '//a[contains(.,"Edit case details")]'
        element :edit_closure, :xpath, '//a[contains(.,"Edit closure details")]'
        element :view_original_case_link, :xpath, '//a[contains(.,"See full original case details ")]'
        end
      end
    end
  end
end
