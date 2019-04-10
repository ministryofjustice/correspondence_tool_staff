require "rails_helper"

describe CasesController, type: :controller do
  describe '#update' do
    let(:manager) { find_or_create :disclosure_bmt_user }
    let(:now)     { Time.local(2018, 5, 30, 10, 23, 33) }

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
                  'date_draft_compliant_dd' => '28',
                  'date_draft_compliant_mm' => '5',
                  'date_draft_compliant_yyyy' => '2018',
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
            expect(kase.date_draft_compliant).to eq Date.new(2018, 5, 28)
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
        context 'received_date too far int past' do
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

        context 'date draft compliant before received date' do
          it 'has error details on the record' do
            kase.date_responded = 3.business_days.after(kase.received_date)
            params['case_foi']['date_draft_compliant_yyyy'] = '2016'
            patch :update, params: params
            expect(assigns(:case).errors.full_messages).to eq ["Date compliant draft uploaded can't be before date received"]
          end
        end

        context 'date draft compliant in future' do
          it 'has error details on the record' do
            params['case_foi']['date_draft_compliant_yyyy'] = '2020'
            patch :update, params: params
            expect(assigns(:case).errors.full_messages).to eq ['Date compliant draft uploaded can\'t be in the future.']
          end
        end

        context 'date draft compliant before received date' do
          it 'has error details on the record' do
            params['case_foi']['date_draft_compliant_yyyy'] = '2016'
            patch :update, params: params
            expect(assigns(:case).errors.full_messages).to eq ["Date compliant draft uploaded can't be before date received"]
          end
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
                'third_party_relationship' => 'Aunty',
                'received_date_dd' => '22',
                'received_date_mm' => '5',
                'received_date_yyyy' => '2018',
                'date_draft_compliant_dd' => '28',
                'date_draft_compliant_mm' => '5',
                'date_draft_compliant_yyyy' => '2018',
                'subject' => 'modified summary',
                'message' => 'moidified full case',
                'flag_for_disclosure_specialists' => 'no',
                'reply_method' => 'send_by_post',
                'email' => 'modified@Moj.com',
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
            expect(kase.date_draft_compliant).to eq Date.new(2018, 5, 28)
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

    context 'ico case' do
      let(:kase)  do
        create :accepted_ico_foi_case
      end

      let(:params) do
          {
              'correspondence_type'=>'ico',
              'case_ico' => {
                'ico_officer_name' => 'C00KYM0N',
                'ico_reference_number' => 'NEWREFNOMNOMNOM',
                'received_date_dd' => '1',
                'received_date_mm' => '5',
                'received_date_yyyy' => '2018',
                'date_draft_compliant_dd' => '13',
                'date_draft_compliant_mm' => '5',
                'date_draft_compliant_yyyy' => '2018',
                'internal_deadline_dd' => '15',
                'internal_deadline_mm' => '5',
                'internal_deadline_yyyy' => '2018',
                'external_deadline_dd' => '26',
                'external_deadline_mm' => '5',
                'external_deadline_yyyy' => '2018',
                'message' => 'modified full request'
              },
              'commit' => 'Submit',
              'id' =>  kase.id.to_s
          }
      end

      context 'valid params' do
        it 'updates the case' do
          patch :update, params: params
          kase.reload

          expect(kase.ico_officer_name).to eq 'C00KYM0N'
          expect(kase.ico_reference_number).to eq 'NEWREFNOMNOMNOM'
          expect(kase.message).to eq 'modified full request'
          expect(kase.received_date).to eq Date.new(2018, 5, 1)
          expect(kase.internal_deadline).to eq Date.new(2018, 5, 15)
          expect(kase.external_deadline).to eq Date.new(2018, 5, 26)
          expect(kase.date_draft_compliant).to eq Date.new(2018, 5, 13)
        end

        it 'redirects to show page' do
          patch :update, params: params
          expect(response).to redirect_to case_path(kase.id)
        end
      end
    end
  end
end
