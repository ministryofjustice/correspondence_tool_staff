# == Schema Information
#
# Table name: search_index
#
#  id       :integer          not null, primary key
#  case_id  :integer          not null
#  document :tsvector         not null
#

class SearchIndexInvalidMethodError < RuntimeError

end

class SearchIndex < ActiveRecord::Base

  self.table_name = :search_index

  SEARCHABLE_FIELDS_AND_RANKS = {
      requestor_name:       'A',
      subject:              'B',
      message:              'C',
      business_unit_name:   'D'
  }


  def self.update_document(kase)
    record = Case::Base.find(kase.id)
    document = convert_to_tsvector
    if record.nil?
      insert_document(kase.id, document)
    else
      update_document(kase.id, document)
    end
  end


  def self.insert_document(kase_id, document)
    sql = %|INSERT INTO "search_index" (case_id, document) values ( #{kase_id}, to_tsvector('#{document}'))|
    puts sql
    connection.execute(sql)
  end


  def self.business_unit_name
    responding_team&.name
  end


  def self.convert_to_tsvector
    fields = []
    SEARCHABLE_FIELDS_AND_RANKS.each do |field_name, rank|
      fields << "setweight(to_tsvector('english', #{__send__(field_name)}), '#{rank}')"
    end
    fields.join(' || ')
  end




  def save;     raise SearchIndexInvalidMethodError; end
  def save!;    raise SearchIndexInvalidMethodError; end
  def create;   raise SearchIndexInvalidMethodError; end
  def update;   raise SearchIndexInvalidMethodError; end
  def update!;  raise SearchIndexInvalidMethodError; end


end
