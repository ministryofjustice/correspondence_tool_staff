# require 'rails_helper'
#
# def allow_case_policy(policy_name)
#   policy = double('Pundit::Policy', policy_name => true)
#   allow(view).to receive(:policy).with(@kase).and_return(policy)
# end
#
# def disallow_case_policy(policy_name)
#   policy = double('Pundit::Policy', policy_name => false)
#   allow(view).to receive(:policy).with(@kase).and_return(policy)
# end
#
# describe 'cases/case_attachments.html.slim', type: :view do
#   describe "#each" do
#     before(:all) do
#       @upload_group_1 = '20170608101112'
#       @upload_group_2 = '20170612114201'
#       @timestamp_1 = '08 Jun 2017 10:11'
#       @timestamp_2 = '12 Jun 2017 11:42'
#       @kase = create :case_with_response
#       @responder_1 = @kase.responding_team.users.first
#       @responder_2 = @kase.responding_team.users.last
#       @kase.attachments.first.update!(upload_group: @upload_group_1, user_id: @responder_1.id)
#
#
#       2.times do
#         @kase.attachments << create(:correspondence_response, upload_group: @upload_group_1, user_id: @responder_1.id)
#       end
#
#       2.times do
#         @kase.attachments << create(:correspondence_response, upload_group: @upload_group_2, user_id: @responder_2.id)
#       end
#     end
#
#     after(:all) do
#       DbHousekeeping.clean
#     end
#
#     describe "as a responder" do
#       describe '#actions' do
#         xit 'should have a "Remove" link' do
#
#           allow_case_policy(:can_remove_attachment?)
#
#           render partial: 'cases/case_attachments.html.slim',
#                  locals:{ case_details: @kase}
#
#           partial =  case_attachments_section(rendered)
#
#
#           ap partial
#         end
#
#         xfit 'should have a preview link' do
#
#         end
#
#         xfit 'should have a Delete link' do
#
#         end
#
#         xfit
#       end
#
#     end
#   end
# end
