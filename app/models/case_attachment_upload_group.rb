class CaseAttachmentUploadGroup
  include Comparable

  attr_reader :user, :collection, :timestamp, :team_name

  def initialize(array_of_time_and_user_id, role, kase, collection)
    @timestamp = get_time(array_of_time_and_user_id.first)
    @user = User.find(array_of_time_and_user_id.last)
    @collection = collection.to_a
    team = kase.team_for_user(@user, role)
    @team_name = team.nil? ? "" : team.name
  end

  def date_time
    @timestamp.strftime(Settings.default_time_format)
  end

  def ids
    @collection.map(&:id)
  end

  def any?
    @collection.any?
  end

  def delete!(case_attachment_id)
    if @collection.map(&:id).include?(case_attachment_id)
      @collection.delete_if { |ca| ca.id == case_attachment_id }
    else
      raise ArgumentError, "Specified CaseAttachmentId (#{case_attachment_id}) not in collection"
    end
  end

  def <=>(other)
    other.timestamp <=> @timestamp
  end

private

  def get_time(upload_group)
    Time.find_zone("Etc/UTC").parse(upload_group)
  end
end
