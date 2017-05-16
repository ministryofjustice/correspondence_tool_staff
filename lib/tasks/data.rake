#################################################################
#                                                               #
#   ENSURE ALL DATA MIGRATIONS ARE IDEMPOTENT                   #
#                                                               #
#################################################################

namespace :data do
  namespace :migrate do

    desc 'run all data migrations'
    task :all => [:environment, :add_refusal_reasons] {}

    desc 'add requires refusal reasons to non-granted outcomes'
    task :add_refusal_reasons => :environmment do

    end

    desc 'Add full names and real email addresses to dev users'
    task :add_names_to_dev_users do
      puts '>>> adding full names and email addresses to dev users'
      update_development_users
    end

    desc 'Fix responded transitions where assignee and user ids are the actual object'
    task :fix_responded_transition_user_metadata => [:environment] do
      CaseTransition.responded.each do |transition|
        fix_transition_user_metadata(transition, 'user_id')
        fix_transition_user_metadata(transition, 'assignee_id')
      end
    end

    desc 'Alter sequencing of refusal reasons'
    task :refusal_reason_resequence => :environment do
      {
        'Exemption applied' => 110,
        'Information not held' => 120,
        '(s1(3)) or (s8(1)) - Advice & assistance/clarification' => 130,
        '(s12) - Exceeded cost' => 140,
        '(s14(1)) - Vexatious' => 150,
        '(s14(2)) - Repeated request' => 160
      }.each do |name, new_sequence|
        rec = CaseClosure::RefusalReason.find_by_name(name)
        raise "Record with name #{name} not found" if rec.nil?
        rec.update(sequence_id: new_sequence)
      end
    end

    desc 'Make Previews for all existing docs'
    task make_previews: :environment do
      atts = CaseAttachment.where(preview_key: nil)
      atts.each do |att|
        puts "creating PDF for attachment #{att.id}"
        PdfMakerJob.perform_now(att.id)
      end
    end

    desc 'Removes PDF conversions of image files'
    task :image_pdf_remove => :environment do
      image_extensions = %w( .jpg .jpeg .bmp .gif .png )
      attachments = CaseAttachment.all
      attachments.each do |att|
        # puts ">>>>>>>>>>>>>> looking at att. #{att.id} #{att.key} #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
        if File.extname(att.key).downcase.in?(image_extensions) && File.extname(att.preview_key).downcase == '.pdf'
          puts "PROCESSING ATTACHMENT #{att.id} with key: #{att.preview_key} #{__FILE__}:#{__LINE__}"
          obj = CASE_UPLOADS_S3_BUCKET.object(att.preview_key)
          obj.delete
          att.update(preview_key: att.key)
        end
      end
    end

    desc 'Sets internal deadline on all cases'
    task set_internal_deadline: :environment do
      Case.all.each do |kase|
        kase.__send__(:set_internal_deadline) if kase.internal_deadline.nil?
      end
    end


  end
end



def fix_transition_user_metadata(transition, field)
  if transition.metadata[field].respond_to? :has_key?
    if transition.metadata[field].has_key? "id"
      puts "CaseTransition #{transition.id}: fixing #{field}"
      transition.update_attribute field, transition.metadata[field]["id"]
    else
      puts "CaseTransition #{transition.id}: #{field} is a hash but could not find 'id' entry"
    end
  end
end

def update_development_users
  user_details = {
    'assigner' => ['Ass Igner', 'correspondence-staff-dev+ass.igner@digital.justice.gov.uk'],
    'drafter' => ['Draughty Hall', 'correspondence-staff-dev+drafty.hall@digital.justice.gov.uk'],
    'approver' => ['App Rover', 'correspondence-staff-dev+app.rover@digital.justice.gov.uk'],
  }
  %w(drafter approver assigner).each do |role|
    email = "#{role}@localhost"
    user = User.where(email: email).first
    if user.nil?
      puts "Unable to find user with email #{email}"
    else
      user.email = user_details[role].last
      user.full_name = user_details[role].first
      user.save!
      puts "User #{user.full_name} updated with email #{user.email}"
    end
  end
end
