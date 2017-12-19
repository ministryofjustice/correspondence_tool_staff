class DatabaseAnonymizer

  $arel_silence_type_casting_deprecation = true

  CLASSES_TO_ANONYMISE = [ Case, User, CaseTransition ]

  def initialize(filename)
    @filename = File.expand_path(filename)
    @batch_size = 1_000
  end

  def run
    CLASSES_TO_ANONYMISE.each { |klass| anonymise_class(klass) }
  end

  private

  def anonymise_class(klass)
    File.open(@filename, 'a') do |fp|
      klass.find_each(batch_size: @batch_size) do |object|
        insert_statement = if object.is_a?(Case)
                             insert_stmt_for_case(object)
                           elsif object.is_a?(User)
                             insert_stmt_for_user(object)
                           elsif object.is_a?(CaseTransition)
                             insert_stmt_for_case_transition(object)
                           else
                             raise "Unexpected object #{object.class}"

                           end
        fp.puts insert_statement
      end
    end
  end


  def insert_stmt_for_case(object)
    kase = anonymize_case(object)
    kase.class.arel_table.create_insert.tap { |im|
      im.insert(kase.send(:arel_attributes_with_values_for_create, attrs_without_properties(kase)))
    }.to_sql + ';'
  end

  def insert_stmt_for_user(object)
    user = anonymize_user(object)
    user.class.arel_table.create_insert.tap { |im|
      im.insert(user.send(:arel_attributes_with_values_for_create, user.attribute_names))
    }.to_sql + ';'
  end

  def insert_stmt_for_case_transition(object)
    ct = anonymise_case_transition(object)
    ct.class.arel_table.create_insert.tap { |im|
      im.insert(ct.send(:arel_attributes_with_values_for_create, attrs_without_metadata(ct)))
    }.to_sql + ';'
  end

  def attrs_without_properties(object)
    object.attribute_names - object.properties.keys
  end

  def attrs_without_metadata(object)
    object.attribute_names - object.metadata.keys
  end


  def anonymize_user(user)
    unless user.email =~ /@digital.justice.gov.uk$/
      user.full_name = Faker::Name.unique.name
      user.email = Faker::Internet.email(user.full_name)
    end
    user
  end

  def anonymize_case(kase)
    kase.name = Faker::Name.name
    kase.email = Faker::Internet.email(kase.name)
    kase.subject = initial_letters(kase.subject) + Faker::Company.catch_phrase
    kase.message = Faker::Lorem.paragraph
    kase.postal_address = fake_address unless kase.postal_address.blank?
    kase
  end

  def anonymise_case_transition(ct)
    ct.message = initial_letters(ct.message) + "\n\n" + Faker::Lorem.paragraph unless ct.message.nil?
    ct
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
end
