class CaseAttachmentUploadGroupCollection

  def initialize(kase, attachments, role)
    groups_keyed_by_array_of_time_and_user_id = attachments.group_by { |at| [at.upload_group, at.user_id] }
    @grouped_collection = []
    groups_keyed_by_array_of_time_and_user_id.each do | array_of_time_and_user_id, collection|
      @grouped_collection << CaseAttachmentUploadGroup.new(array_of_time_and_user_id, role, kase, collection)
    end
    @grouped_collection.sort!
  end

  def any?
    @grouped_collection.any?
  end

  # each returns an instance of GroupedCollection
  def each(&block)
    @grouped_collection.each { |gc| block.call(gc) }
  end

  def for_case_attachment_id(case_attachment_id)
    result = @grouped_collection.detect { | gc | gc.ids.include?(case_attachment_id) }
    raise ArgumentError.new "No upload group contains a case attachment with id #{case_attachment_id}" unless result
    result
  end
end
