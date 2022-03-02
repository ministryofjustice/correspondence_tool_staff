module PageObjects
  module Sections
    module Cases
      module ICO
        class CaseDetailsSection < SitePrism::Section

          element :section_heading, '.case-details .request--heading'

          section :case_type, 'tr.case-type' do
            element :ico_trigger, 'td .ico-trigger'
            element :data, 'td'
          end

          section :ico_reference, 'tr.ico-reference' do
            element :data, 'td'
          end

          section :ico_officer_name, 'tr.ico-officer-name' do
            element :data, 'td'
          end

          section :date_received, 'tr.date-received' do
            element :data, 'td'
          end

          section :internal_deadline, 'tr.case-internal-deadline' do
            element :data, 'td:nth-child(2)'
          end

          section :external_deadline, 'tr.case-external-deadline' do
            element :data, 'td:nth-child(2)'
          end

          section :original_internal_deadline, 'tr.case-original-internal-deadline' do
            element :data, 'td:nth-child(2)'
          end

          section :original_external_deadline, 'tr.case-original-external-deadline' do
            element :data, 'td:nth-child(2)'
          end

          section :name, 'tr.requester-name' do
            element :data, 'td'
          end

          section :email, 'tr.requester-email' do
            element :data, 'td'
          end

          section :address, 'tr.requester-address' do
            element :data, 'td'
          end

          section :requester_type, 'tr.requester-type' do
            element :data, 'td'
          end

          section :delivery_method, 'tr.delivery-method' do
            element :data, 'td'
          end

          section :responders_details, '.responder-details' do
            section :team, '.team' do
              element :data, 'td:nth-child(2)'
            end

            section :name, '.responder-name' do
              element :data, 'td:nth-child(2)'
            end
          end

          section :response_details, '.response-details' do
            section :date_responded, '.date-responded' do
              element :data, 'td'
            end

            section :timeliness, '.timeliness' do
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
