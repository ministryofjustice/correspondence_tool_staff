FactoryBot.define do

  factory :overturned_ico_sar, class: Case::OverturnedICO::SAR do
    current_state                   { 'unassigned' }
    sequence(:ico_reference)        { |n| "ICO-SAR-1234-#{n}" }
    original_ico_appeal             { create :ico_sar_case }
    original_case                   { create :sar_case }
    received_date                   { Date.yesterday }
    internal_deadline               { 10.days.from_now }
    external_deadline               { 20.days.from_now }
    escalation_deadline             { 3.days.from_now }
    reply_method                    { 'send_by_email' }
    email                           { 'dave@moj.com' }
  end

  factory :overturned_ico_foi, class: Case::OverturnedICO::FOI do
    current_state                   { 'unassigned' }
    sequence(:ico_reference)        { |n| "ICO-FOI-1234-#{n}" }
    original_ico_appeal             { create :ico_foi_case }
    original_case                   { create :foi_case }
    received_date                   { Date.yesterday }
    internal_deadline               { 10.days.from_now }
    external_deadline               { 20.days.from_now }
    escalation_deadline             { 3.days.from_now }
    reply_method                    { 'send_by_email' }
    email                           { 'dave@moj.com' }
  end
end
