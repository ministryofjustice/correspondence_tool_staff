module PageObjects
  module Sections
    module Cases
      class CaseDetailsSection < SitePrism::Section

        section :basic_details, '.basic-details' do

          section :case_type, 'tr.case-type' do
            element :foi_trigger, 'td .foi-trigger'
            element :data, 'td'
          end

          section :date_received, 'tr.date-received' do
            element :data, 'td'
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
        end


        section :responders_details, '.responder-details' do
          section :team, '.team' do
            element :data, 'td'
          end

          section :name, '.responder-name' do
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

          section :time_taken, '.time-taken' do
            element :data, 'td'
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
      end
    end
  end
end
