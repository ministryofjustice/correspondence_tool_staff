module NewCase
  extend ActiveSupport::Concern

  def new_case_for(correspondence_type)
    default_subclass = correspondence_type.sub_classes.first
    authorize default_subclass, :can_add_case?

    @case = default_subclass.new.decorate
    @case_types = correspondence_type.sub_classes.map(&:to_s)
    @s3_direct_post = S3Uploader.for(@case, 'requests')
  end
end
