require "rails_helper"

describe CasesController, type: :controller do
  describe '#update' do
    let(:manager) { create :disclosure_bmt_user }
    let(:now) { Time.local(2018, 5, 30, 10, 23, 33) }

    before do
      sign_in manager
    end

    context 'foi case' do
      let(:kase)  do
        create :accepted_case,
               name: 'Original Name',
               email: 'original_email@moj.com',
               message: 'Original message',
               received_date: now.to_date,
               postal_address: 'Original Postal Address',
               subject: 'Original subject',
               requester_type: 'member_of_the_public',
               delivery_method: 'sent_by_email'
      end
      let(:params) do
          {
              'correspondence_type'=>'foi',
              'case_foi' => {
                  'name' => 'Modified name',
                  'email' => 'modified_email@stephenrichards.eu',
                  'postal_address' => 'modified address',
                  'requester_type' => 'what_do_they_know',
                  'received_date_dd' => '26',
                  'received_date_mm' => '5',
                  'received_date_yyyy' => '2018',
                  'subject' => 'modified subject',
                  'message' => 'modified full request'
              },
              'commit' => 'Submit',
              'id' =>  kase.id.to_s
          }
      end

      context 'valid params' do
        it 'updates the case' do
          Timecop.freeze(now) do
            patch :update, params: params
            kase.reload

            expect(kase.name).to eq 'Modified name'
            expect(kase.email).to eq 'modified_email@stephenrichards.eu'
            expect(kase.message).to eq 'modified full request'
            expect(kase.received_date).to eq Date.new(2018, 5, 26)
            expect(kase.postal_address).to eq 'modified address'
            expect(kase.subject).to eq 'modified subject'
            expect(kase.requester_type).to eq 'what_do_they_know'
          end
        end

        it 'redirects to show page' do
          Timecop.freeze(now) do
            patch :update, params: params
            expect(response).to redirect_to case_path(kase.id)
          end
        end
      end


      context 'invalid params' do

        before(:each) { params['case_foi']['received_date_yyyy'] = '2017' }

        it 'does not update the record' do
          original_kase = kase.clone
          patch :update, params: params
          expect(kase.reload).to eq original_kase
        end

        it 'has error details on the record' do
          patch :update, params: params
          expect(assigns(:case).errors.full_messages).to eq ['Received date too far in past.']
        end

        it 'redisplays the edit page' do
          patch :update, params: params
          expect(response).to render_template :edit
        end
      end
    end

    context 'sar case' do
      let(:kase)  do
        create :accepted_sar,
               name: 'Original Name',
               email: 'original_email@moj.com',
               message: 'origninal full case',
               received_date: now.to_date,
               postal_address: '',
               subject: 'Original summary',
               third_party: false,
               reply_method: 'send_by_email',
               subject_type: 'offender',
               subject_full_name: 'original subject'
      end
      let(:params) do
        {
            'correspondence_type' => 'sar',
            'case_sar' => {
                'subject_full_name' => 'modified subject',
                'subject_type' => 'member_of_the_public',
                'third_party' => 'true',
                'name' => 'the new requestor',
<<<<<<< HEAD
                'received_date_dd' => '22', 
                'received_date_mm' => '5', 
                'received_date_yyyy' => '2018', 
                'subject' => 'modified summary', 
                'message' => 'moidified full case', 
                'flag_for_disclosure_specialists' => 'no', 
                'reply_method' => 'send_by_post', 
                'email' => 'modified@Moj.com', 
=======
                'third_party_relationship' => 'Aunty',
                'received_date_dd' => '22',
                'received_date_mm' => '5',
                'received_date_yyyy' => '2018',
                'subject' => 'modified summary',
                'message' => 'moidified full case',
                'flag_for_disclosure_specialists' => 'no',
                'reply_method' => 'send_by_post',
                'email' => 'modified@Moj.com',
>>>>>>> CT-1754 add authorise and helper test
                'postal_address' => 'modified address'
            },
            'commit' => 'Submit',
            'id' => kase.id.to_s
        }
      end

      context 'valid params' do
        it 'updates the case' do
          Timecop.freeze(now) do
            patch :update, params: params
            kase.reload

            expect(kase.name).to eq 'the new requestor'
            expect(kase.email).to eq 'modified@Moj.com'
            expect(kase.message).to eq 'moidified full case'
            expect(kase.received_date).to eq Date.new(2018, 5, 22)
            expect(kase.postal_address).to eq 'modified address'
            expect(kase.subject).to eq 'modified summary'
            expect(kase.requester_type).to be_nil
            expect(kase.third_party).to be true
            expect(kase.reply_method).to eq 'send_by_post'
            expect(kase.subject_type).to eq 'member_of_the_public'
            expect(kase.subject_full_name).to eq 'modified subject'
          end
        end

        it 'redirects to show page' do
          Timecop.freeze(now) do
            patch :update, params: params
            expect(response).to redirect_to case_path(kase.id)
          end
        end
      end

      context 'invalid params' do
        before(:each) { params['case_sar']['received_date_yyyy'] = '2017' }

        it 'does not update the record' do
          original_kase = kase.clone
          patch :update, params: params
          expect(kase.reload).to eq original_kase
        end

        it 'has error details on the record' do
          patch :update, params: params
          expect(assigns(:case).errors.full_messages).to include('Received date too far in past.')
        end

        it 'redisplays the edit page' do
          patch :update, params: params
          expect(response).to render_template :edit
        end
      end
    end
  end

end
