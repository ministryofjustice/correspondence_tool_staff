class DatabaseAnonymizer

  attr_reader :tables_to_anonymised

  CLASSES_TO_ANONYMISE = [ Team, TeamProperty, ::Warehouse::CaseReport, Case::Base, User, CaseTransition, CaseAttachment]

  class RecordToCopySql
    def initialize(record)
      @record = record
      @table = record.class.arel_table
      @type_caster = @table.send(:type_caster)
    end

    def to_sql
      compile_to_copy_sql(extract_data)
    end

    private 
    
    def process_value(data)
      if data.nil?
        '\N'
      elsif data.is_a? String
        data.inspect.gsub('"', '')
      else
        data
      end
    end

    def extract_data
      attrs = {}
      @record.class.column_names.each do | attribute |
        value = @record._read_attribute(attribute)
        if value.is_a? Hash
          value.each do | sub_attr, sub_value |
            value[sub_attr] = process_value(sub_value) unless sub_value.blank?
          end
          attrs[attribute] = @type_caster.type_cast_for_database(attribute, value) 
        else
          real_value = @type_caster.type_cast_for_database(attribute, value)
          attrs[attribute] = process_value(real_value)
        end
      end
      attrs
    end

    def compile_to_copy_sql(extract_data)
      extract_data.values().join("\t").gsub("'", '''')
    end
  end
 
  class RecordToInsertSql

    def initialize(record)
      @record = record
      @table = record.class.arel_table
      @type_caster = @table.send(:type_caster)
    end

    def to_sql
      @table.compile_insert(extract_data).to_sql
    end

    private 
    

    def extract_data
      # note attributes_for_creater is a private method
      # therefore not great to depend on.
      # call to it extracted here for later refactor.
      attribute_names = @record.send(:attributes_for_create, @record.class.column_names)

      attrs = add_values(attribute_names)
      type_cast(attrs)
    end

    def type_cast(data)
      data.each do |attribute, value|
        data[attribute] = @type_caster.type_cast_for_database(attribute.name, value)
      end
    end

    def add_values(attribute_names)
      attrs = {}
      @record.class.column_names.each do |name|
        attrs[@table[name]] = @record._read_attribute(name)
      end
      attrs
    end
  end

  def initialize(max_num_of_records_per_group=10000)
    @tables_to_anonymised = {}
    @max_num_of_records_per_group = max_num_of_records_per_group
    CLASSES_TO_ANONYMISE.each { |klass| @tables_to_anonymised[klass.table_name] = klass }
  end

  def run
    CLASSES_TO_ANONYMISE.each { |klass| anonymise_class(klass) }
  end

  def anonymise_class(klass, filename)
    files = []
    counter = 0
    number_of_groups = cal_number_of_groups(klass)

    number_of_groups.times do | number |
      number_file = "%.#{number_of_groups.to_s.length}i" % ( counter + 1 )
      full_path_filename = File.expand_path("#{filename}.#{number_file}.sql")
      File.open(full_path_filename, 'a') do |fp|
        puts full_path_filename
        files << full_path_filename

        sql_settings_start(fp, klass)

        offset = @max_num_of_records_per_group * counter
        limit = @max_num_of_records_per_group
        klass.offset(offset).limit(limit).order(klass.primary_key.to_sym).each do | record |
          # insert_statement = raw_sql_from_record(record) + ';'
          insert_statement = raw_sql_from_record(record)
          fp.puts insert_statement
        end

        sql_settings_end(fp)
      end
      counter += 1      
    end
    files
  end

  private

  def cal_number_of_groups(klass)
    (Float(klass.all.count)/@max_num_of_records_per_group).ceil()
  end

  def sql_settings_start(fp, class_model)
    # Search path with public space
    fp.puts "SELECT pg_catalog.set_config('search_path', 'public', false);"

    fp.puts "\n"
    fp.puts "\n"

    # Set the fields for copy command
    fp.puts "COPY #{class_model.table_name} ( #{class_model.column_names.join(", ")} ) FROM stdin;"
  end

  def sql_settings_end(fp)
    fp.puts '\.'
    fp.puts "\n"
    fp.puts "\n"
end

  # The key function for producing the insert sqls 
  def raw_sql_from_record(record)
    record = self.send("anonymize_#{record.class.table_name}", record)
    RecordToCopySql.new(record).to_sql
  end

  #
  # The followings are the functions for anonymising specific table/class
  #

  def anonymize_users(user)
    unless user.email =~ /@digital.justice.gov.uk$/
      user.full_name = Faker::Name.unique.name
      user.email = Faker::Internet.email(name: user.full_name)
    end
    user
  end

  # Anonymize Cases table including all those case types
  def anonymize_cases(kase)
    kase.name = Faker::Name.name unless kase.class unless kase.class.name.start_with?("Case::ICO")
    kase.subject = initial_letters(kase.subject) + Faker::Company.catch_phrase unless kase.class.name.start_with?("Case::ICO")
    kase.email = Faker::Internet.email(name:kase.name)
    kase.message = Faker::Lorem.paragraph unless kase.message.blank?
    kase.postal_address = fake_address unless kase.postal_address.blank?

    # anonymize some fields only relevent to specific case type
    begin
      self.send("anonymize_#{kase.class.name.parameterize.underscore}", kase)
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
    kase.subject_address = fake_address unless kase.subject_address.blank?
    kase.subject_full_name = Faker::Name.name
    kase.subject_aliases = Faker::Name.name unless kase.subject_aliases.blank?
    kase.case_reference_number = Faker::Code.asin unless kase.case_reference_number.blank?
    kase.other_subject_ids = fake_subject_ids(kase.other_subject_ids) unless kase.other_subject_ids.blank?
    kase.prison_number = Faker::Code.asin unless kase.prison_number.blank?
    kase.requester_reference = "F" + Faker::Invoice.reference unless kase.requester_reference.blank?
    kase.third_party_name = Faker::Name.name unless kase.third_party_name.blank?
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

  def anonymize_case_overturnedico_sar(kase)
    anonymize_case_overturnedico_foi(kase)
  end
  
  # Anonymize case_transition table
  def anonymize_case_transitions(ct)
    ct.message = initial_letters(ct.message) + "\n\n" + Faker::Lorem.paragraph unless ct.message.nil?
    ct
  end


  # Anonymize warehouse_case_reports table
  # This table is difficult one, as it contains the informaton from multiple tables 
  # like cases, teams, users which cannot be easily cooperated during this anonymization process
  # The approach is to anonymize this table anyway, it wil cause the inconsistences between this 
  # table and other main entries table, which can be fixed later by triggering the syncing process manually
  # after dumping the anonymized data into target database
  def anonymize_warehouse_case_reports(kase)
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
    kase
  end

  def anonymize_teams(team)
    team.email = Faker::Internet.email(name:team.name) unless team.email.blank?
    team
  end
  
  def anonymize_team_properties(tp)
    tp.key = Faker::Name.name
    tp.value = Faker::Lorem.sentence
    tp
  end

  def anonymize_data_requests(data_request)
    data_request.request_type_note = Faker::Lorem.sentence
    data_request
  end

  def anonymize_case_attachments(ca)
    ca.key = Faker::File.file_name + SecureRandom.uuid 
    ca.preview_key = Faker::File.file_name
    ca
  end

  def initial_letters(phrase)
    # words = phrase.split(' ')
    # "[#{words[0..9].map{ |w| w.first.upcase }.join('')}]"
    "[#{Faker::Name.name}]"
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
    Array.new(subject_ids.count) { Faker::Code.asin }.join(', ')
  end

end
