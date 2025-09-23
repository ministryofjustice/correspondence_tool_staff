#################################################################
#                                                               #
#   ENSURE ALL DATA MIGRATIONS ARE IDEMPOTENT                   #
#                                                               #
#################################################################

namespace :data do
  namespace :migrate do
    desc "run all data migrations"
    task all: %i[environment add_refusal_reasons] do
    end

    desc "add requires refusal reasons to non-granted outcomes"
    task add_refusal_reasons: :environmment do
    end

    desc "Add full names and real email addresses to dev users"
    task add_names_to_dev_users: :environment do
      puts ">>> adding full names and email addresses to dev users"
      update_development_users
    end

    desc "Fix responded transitions where assignee and user ids are the actual object"
    task fix_responded_transition_user_metadata: [:environment] do
      CaseTransition.responded.each do |transition|
        fix_transition_user_metadata(transition, "user_id")
        fix_transition_user_metadata(transition, "assignee_id")
      end
    end

    desc "Alter sequencing of refusal reasons"
    task refusal_reason_resequence: :environment do
      {
        "Exemption applied" => 110,
        "Information not held" => 120,
        "s8(1) - Conditions for submitting request not met" => 130,
        "(s12) - Exceeded cost" => 140,
        "(s14(1)) - Vexatious" => 150,
        "(s14(2)) - Repeated request" => 160,
      }.each do |name, new_sequence|
        rec = CaseClosure::RefusalReason.find_by_name(name)
        raise "Record with name #{name} not found" if rec.nil?

        rec.update!(sequence_id: new_sequence)
      end
    end

    desc "Alter refusal reasons - clarifications to not met"
    task rename_clarifications_reason: :environment do
      rec = CaseClosure::RefusalReason.find_by_name("(s1(3)) or (s8(1)) - Advice & assistance/clarification")

      raise "Record with name (s1(3)) or (s8(1)) - Advice & assistance/clarification not found" if rec.nil?

      rec.update!(name: "s8(1) - Conditions for submitting request not met", abbreviation: "notmet")
    end

    desc "Make Previews for all existing docs"
    task make_previews: :environment do
      atts = CaseAttachment.where(preview_key: nil)
      atts.each do |att|
        puts "creating PDF for attachment #{att.id}"
        PdfMakerJob.perform_now(att.id)
      end
    end

    desc "Removes PDF conversions of image files"
    task image_pdf_remove: :environment do
      image_extensions = %w[.jpg .jpeg .bmp .gif .png]
      attachments = CaseAttachment.all
      attachments.each do |att|
        next unless File.extname(att.key).downcase.in?(image_extensions) && File.extname(att.preview_key).downcase == ".pdf"

        puts "PROCESSING ATTACHMENT #{att.id} with key: #{att.preview_key} #{__FILE__}:#{__LINE__}"
        obj = CASE_UPLOADS_S3_BUCKET.object(att.preview_key)
        obj.delete
        att.update!(preview_key: att.key)
      end
    end

    desc "Sets internal deadline on all cases"
    task set_internal_deadline: :environment do
      Case::Base.all.find_each do |kase|
        kase.__send__(:set_internal_deadline) if kase.internal_deadline.nil?
      end
    end

    desc "Remove orphan PDFs from S3"
    task delete_orphan_pdf: :environment do
      required_pdfs = CaseAttachment.all.map(&:preview_key).compact

      actual_pdfs = CASE_UPLOADS_S3_BUCKET.objects.map(&:key)
      actual_pdfs.delete_if { |key| key !~ /\/response_previews\// }
      pdfs_to_delete = actual_pdfs - required_pdfs
      pdfs_to_delete.each do |key|
        puts "Deleting orphan preview #{key}"
        obj = CASE_UPLOADS_S3_BUCKET.object(key)
        obj.delete
      end
    end

    desc "Add disclosure team assignments to cases taken on by press office."
    task add_disclosure_team: :environment do
      press_office = BusinessUnit.press_office
      dacu_disclosure = BusinessUnit.dacu_disclosure
      Case::Base.with_teams(press_office)
        .find_all { |c| c.assignments.with_teams(dacu_disclosure).blank? }
        .each do |kase|
        puts "Assigning DACU Disclosure to case #{kase.id}"
        press_office_transition = kase.transitions.where(
          event: %w[take_on_for_approval],
        ).metadata_where(
          approving_team_id: press_office.id,
        ).last
        press_officer = if press_office_transition.present?
                          puts "using press officer from take_on_for_approval transition"
                          press_office_transition.user
                        else
                          puts "no previous take_on_for_approval transition found, using first press officer on team"
                          press_office.users.first
                        end
        puts "Assigning DACU Disclosure to case id: #{kase.id}"
        kase.approving_teams << dacu_disclosure
        begin
          puts "Creating 'flag_for_clearance' transition for case id: #{kase.id}"
          kase.state_machine.flag_for_clearance! press_officer,
                                                 press_office,
                                                 dacu_disclosure
        rescue StandardError => e
          puts "!!! transition error received: #{e.class} #{e.message}"
          puts "!!! BUT THAT'S OK because we've already done the assignment,"
          puts "!!! there just won't be an transition for it."
          puts e.backtrace.join("\n\t")
        end
      end

      desc "Add missing flag_as_dps_missing_data property to cases"
      task add_dps_missing_data_flag: :environment do
        sql = <<-SQL
          WITH updated AS (
            UPDATE cases
            SET
              properties = jsonb_set(properties, '{flag_as_dps_missing_data}', 'false'::jsonb),
              updated_at = NOW()
            WHERE
              properties ? 'flag_as_dps_missing_data' = FALSE
            RETURNING *
          )
          SELECT * FROM updated;
        SQL
      end
    end

    desc "Fix invalid Offender SAR cases"
    task fix_invalid_offender_sar_cases: :environment do
      fix_invalid_offender_sar_cases
    end

    desc "Fix invalid Standard SAR cases"
    task fix_invalid_standard_sar_cases: :environment do
      fix_invalid_standard_sar_cases
    end

    namespace :import do
      desc "Import hierarchical team data"
      task teams: :environment do
        require Rails.root.join("lib/rake_task_helpers/team_importer")
        TeamSeeder.new.run
      end
    end
  end
end

def fix_transition_user_metadata(transition, field)
  if transition.metadata[field].respond_to? :has_key?
    if transition.metadata[field].key? "id"
      puts "CaseTransition #{transition.id}: fixing #{field}"
      transition.update_attribute field, transition.metadata[field]["id"] # rubocop:disable Rails/SkipsModelValidations
    else
      puts "CaseTransition #{transition.id}: #{field} is a hash but could not find 'id' entry"
    end
  end
end

def update_development_users
  user_details = {
    "assigner" => ["Ass Igner", "correspondence-staff-dev+ass.igner@digital.justice.gov.uk"],
    "drafter" => ["Draughty Hall", "correspondence-staff-dev+drafty.hall@digital.justice.gov.uk"],
    "approver" => ["App Rover", "correspondence-staff-dev+app.rover@digital.justice.gov.uk"],
  }
  %w[drafter approver assigner].each do |role|
    email = "#{role}@localhost"
    user = User.where(email:).first
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

def fix_invalid_offender_sar_cases
  Case::Base.offender_sar.find_each do |k|
    k.save! unless k.valid?
    unless k.valid?
      p "Item #{k.id}, #{k.type}, #{k.current_state}, Number: #{k.number}, #{k.errors.messages}"
      p "Fixing case..."

      if k.errors.messages[:subject_address] == ["cannot be blank"]
        k.update_attribute(:subject_address, "NO ADDRESS SUPPLIED") # rubocop:disable Rails/SkipsModelValidations
        p "subject_address"
      end

      if k.errors.messages[:postal_address] == ["cannot be blank"]
        k.update_attribute(:postal_address, "NO ADDRESS SUPPLIED") # rubocop:disable Rails/SkipsModelValidations
        p "postal_address"
      end

      if k.errors.messages[:third_party_company_name] == ["cannot be blank if representative name not given"]
        k.update_attribute(:third_party_company_name, "NO COMPANY NAME SUPPLIED") # rubocop:disable Rails/SkipsModelValidations
        p "third_party_company_name"
      end

      if k.errors.messages[:third_party_relationship] == ["cannot be blank"]
        k.update_attribute(:third_party_relationship, "NO RELATIONSHIP SUPPLIED") # rubocop:disable Rails/SkipsModelValidations
        p "third_party_relationship"
      end

      if k.errors.messages[:date_responded] == ["cannot be blank"]
        last_known_date = k.transitions.order(:sort_key)&.last&.created_at&.to_date
        k.update_attribute :date_responded, last_known_date # rubocop:disable Rails/SkipsModelValidations
        p "date_responded"
      end

      p "Case valid - #{k.reload.valid?}"
    end
  end
end

def fix_invalid_standard_sar_cases
  Case::Base.non_offender_sar.find_each do |k|
    k.save! unless k.valid?
    unless k.valid?
      p "Item #{k.id}, #{k.type}, #{k.current_state}, Number: #{k.number}, #{k.errors.messages}"
      p "Fixing case..."

      if k.errors.messages[:late_team_id] == %w[blank_invalid_if_case_late]
        k.update_attribute :late_team_id, 0 # rubocop:disable Rails/SkipsModelValidations
        p "late_team_id"
      end

      p "Case valid - #{k.reload.valid?}"
    end
  end
end
