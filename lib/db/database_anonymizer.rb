class DatabaseAnonymizer

  attr_reader :tables_to_anonymised

  # $arel_silence_type_casting_deprecation = true

  CLASSES_TO_ANONYMISE = [ Case::Base, User, CaseTransition ]

  def initialize()
    @batch_size = 1_000
    @tables_to_anonymised = {}
    CLASSES_TO_ANONYMISE.each { |klass| @tables_to_anonymised[klass.table_name] = klass }
  end

  def run
    CLASSES_TO_ANONYMISE.each { |klass| anonymise_class(klass) }
  end

  def anonymise_class(klass, filename)
    full_path_filename = File.expand_path(filename)
    File.open(full_path_filename, 'a') do |fp|
      sql_settings(fp)
      klass.find_each(batch_size: @batch_size) do | record |
        # Handling the main record 
        insert_statement = raw_sql_from_record(record) + ';'
        fp.puts insert_statement
      end
    end
  end

  private

  def sql_settings(fp)
    fp.puts "SELECT pg_catalog.set_config('search_path', 'public', false);"
  end

  # The key function for producing the insert sqls 
  def raw_sql_from_record(record, related_model: nil)
    model = related_model || record.class
    table = model.arel_table

    record = self.send('anonymize_#{table.table_name}', record)
    values = record.send(:attributes_with_values_for_create, record.class.column_names)
    model = record.class
    substitutes_and_binds = model.send(:_substitute_values, values)
    type_cast(substitutes_and_binds, record)

    insert_manager = table.create_insert
    insert_manager.insert substitutes_and_binds

    insert_manager.to_sql
  end

  def type_cast(data, record)
    data.each do |attribute, value|
      data[attribute] = record.class.arel_table.type_cast_for_database(attribute.name, value)
    end
  end

  #
  # The followings are the functions for anonymising specific table/class
  #

  def anonymize_user(user)
    unless user.email =~ /@digital.justice.gov.uk$/
      user.full_name = Faker::Name.unique.name
      user.email = Faker::Internet.email(name: user.full_name)
    end
    user
  end

  # Anonymize Cases table including all those case types
  def anonymize_case(kase)
    kase.name = Faker::Name.name
    kase.email = Faker::Internet.email(name:kase.name)
    kase.subject = initial_letters(kase.subject) + Faker::Company.catch_phrase
    kase.message = Faker::Lorem.paragraph unless kase.message.blank?
    kase.postal_address = fake_address unless kase.postal_address.blank?

    # anonymize some fields only relevent to specific case type
    begin
      self.send("anonymize_#{kase.class.name.parameterize.underscore}")
    rescue => exception      
    end

    # update the search index in the record
    kase.update_index
    kase
  end

  def anonymize_case_sar_standard(kase)
    kase.subject_full_name = Faker::Name.name
  end

  def anonymize_case_sar_offender(kase)
    kase.subject_full_name = Faker::Name.name
    kase.subject_aliases = Faker::Name.name unless kase.subject_aliases.blank?
    kase.case_reference_number = Faker::Code.asin unless kase.case_reference_number.blank?
    kase.other_subject_ids = fake_subject_ids(kase.other_subject_ids) unless kase.other_subject_ids.blank?
    kase.prison_number = Faker::Code.asin unless kase.prison_number.blank?
    kase.requester_reference = "F" + Faker::Invoice.reference unless kase.requester_reference.blank?
    kase.third_party_company_name = Faker::Company.name unless kase.third_party_company_name.blank?
  end

  def anonymize_case_ico_foi(kase)
    kase.ico_officer_name = Faker::Name.name unless kase.ico_officer_name.blank?
    kase.ico_reference_number = "F" + Faker::Invoice.reference unless kase.ico_reference_number.blank?
    kase.ico_decision_comment = Faker::TvShows::DrWho.quote unless kase.ico_decision_comment.blank?
  end

  def anonymize_case_ico_sar(kase)
    anonymize_case_ico_foi(kase)
  end

  def anonymize_case_overturnedico_foi(kase)
    kase.ico_officer_name = Faker::Name.name unless ase.ico_officer_name.blank?
  end
  
  # Anonymize case_transition table
  def anonymise_case_transition(ct)
    ct.message = initial_letters(ct.message) + "\n\n" + Faker::Lorem.paragraph unless ct.message.nil?
    ct
  end

  # Anonymize case_transition table
  def anonymise_case_transition(ct)
    ct.message = initial_letters(ct.message) + "\n\n" + Faker::Lorem.paragraph unless ct.message.nil?
    ct
  end


  # Anonymize warehouse_case_reports table
  # This table is difficult one, as it contains the informaton from multiple tables 
  # like cases, teams, users which cannot be easily cooperated during this anonymization process
  # The approach is to anonymize this table anyway, it wil cause the inconsistences between this 
  # table and other main entries table, which can be fixed later by triggering the syncing process manually
  # after dumping the anonymized data into target database
  def anonymise_warehouse_case_reports(kase)
    kase.name = Faker::Name.name unless kase.name.blank?
    kase.email = Faker::Internet.email(name:kase.name) unless kase.email.blank?
    kase.sar_subject_full_name = Faker::Name.name unless kase.sar_subject_full_name.blank?
    kase.casework_officer = Faker::Name.name unless kase.casework_officer.blank?
    kase.created_by = Faker::Name.name unless kase.created_by.blank?
    kase.director_general_name = Faker::Name.name unless kase.director_general_name.blank?
    kase.director_name = Faker::Name.name unless kase.director_name.blank?
    kase.deputy_director_name = Faker::Name.name unless kase.deputy_director_name.blank?
    kase.third_party_company_name = Faker::Company.name unless kase.third_party_company_name.blank?
    kase.postal_address = fake_address unless kase.postal_address.blank?
    kase.message = Faker::Lorem.paragraph unless kase.message.blank?
  end

  def anonymise_teams(team)
    team.email = Faker::Internet.email(name:kase.name) unless team.email.blank?
  end

  def anonymise_team_properites(tp)
    tp.key = Faker::Name.name
    tp.value = Faker::Lorem.sentence
  end

  def anonymise_data_requests(tp)
    tp.key = Faker::Name.name
    tp.value = Faker::Lorem.sentence
  end

  def anonymise_case_attachments(ca)
    ca.key = Faker::File.file_name
    ca.preview_key = Faker::File.file_name
  end

  def initial_letters(phrase)
    words = phrase.split(' ')
    "[#{words[0..9].map{ |w| w.first.upcase }.join('')}]"
  end

  def fake_address
    [
        Faker::Address.street_address,
        Faker::Address.city,
        Faker::Address.state,
        Faker::Address.zip
    ].join("\n")
  end

  def fake_subject_ids(subject_ids_str)
    subject_ids1 = subject_ids_str.split(",")
    subject_ids2 = subject_ids_str.split(" ")
    subject_ids = (subject_ids1.count > subject_ids2.count ? subject_ids1 : subject_ids2)
    Array.new(subject_ids.count) { Faker::Code.asin }
  end

end
