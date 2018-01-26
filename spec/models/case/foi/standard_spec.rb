require "rails_helper"

describe Case::FOI::Standard do
  describe 'requester_type' do
    it { should validate_presence_of(:requester_type)  }

    it { should have_enum(:requester_type).
                  with_values(
                    [
                      'academic_business_charity',
                      'journalist',
                      'member_of_the_public',
                      'offender',
                      'solicitor',
                      'staff_judiciary',
                      'what_do_they_know'
                    ]
                  )
    }
  end

  describe 'delivery_method' do
    it { should validate_presence_of(:delivery_method) }

    it { should have_enum(:delivery_method).
                  with_values(
                    [
                      'sent_by_email',
                      'sent_by_post'
                    ]
                  )
    }
  end
end
