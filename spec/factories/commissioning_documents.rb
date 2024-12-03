# == Schema Information
#
# Table name: commissioning_documents
#
#  id                   :bigint           not null, primary key
#  data_request_id      :bigint
#  template_name        :enum
#  sent                 :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  attachment_id        :bigint
#  data_request_area_id :bigint
#
FactoryBot.define do
  factory :commissioning_document do
    data_request
    data_request_area
    template_name { "standard" }
  end
end
