module PageObjects
  module Sections
    class CaseDetailsSection < SitePrism::Section

      section :basic_details, '.basic-details' do
        section :date_received, 'tr.date-received' do
          element :heading, 'th'
          element :data, 'td'
        end

        section :name, 'tr.requester-name' do
          element :heading, 'th'
          element :data, 'td'
        end

        section :email, 'tr.requester-email' do
          element :heading, 'th'
          element :data, 'td'
        end

        section :address, 'tr.requester-address' do
          element :heading, 'th'
          element :data, 'td'
        end

        section :requester_type, 'tr.requester-type' do
          element :heading, 'th'
          element :data, 'td'
        end
      end


      section :responders_details, '.responder-details' do
        section :team, '.team' do
          element :heading, 'th'
          element :data, 'td'
        end

        section :name, '.responder-name' do
          element :heading, 'th'
          element :data, 'td'
        end
      end


      section :response_details, '.response-details' do

        section :date_responded, '.date-responded' do
          element :heading, 'th'
          element :data, 'td'
        end

        section :timeliness, '.timeliness' do
          element :heading, 'th'
          element :data, 'td'
        end

        section :time_taken, '.time-taken' do
          element :heading, 'th'
          element :data, 'td'
        end


        section :outcome, '.outcome' do
          element :heading, 'th'
          element :data, 'td'
        end

        section :refusal_reason, '.refusal-reason' do
          element :heading, 'th'
          element :data, 'td'
        end


        section :exemptions, '.exemptions' do
          element :heading, 'th'
          elements :list, 'td ul li'
        end
      end
    end
  end
end
