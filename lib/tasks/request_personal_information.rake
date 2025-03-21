namespace :request_personal_information do
  desc "Set old requests as deleted, and destroy all uploaded files"
  task delete_expired: :environment do
    PersonalInformationRequest.ready_to_delete.find_each(&:soft_delete)
  end
end
