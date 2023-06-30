module NewCase
  extend ActiveSupport::Concern

  # default_subclass
  #
  # We don't know what kind of case type (FOI Standard, IR Timeliness, etc)
  # they want to create yet, but we need to authenticate them against some
  # kind of case class, so pick the first subclass available to them. This
  # could be improved by making case_subclasses a list of the case types
  # they are permitted to create, and when that list is empty rejecting
  # authorisation.
  def new_case_for(correspondence_type, default_subclass: correspondence_type.sub_classes.first)
    valid_type = validate_correspondence_type(@correspondence_type_key)

    if valid_type == :ok
      authorize default_subclass, :can_add_case?

      @case = default_subclass.new.decorate
      @case_types = correspondence_type.sub_classes.map(&:to_s)
      @s3_direct_post = S3Uploader.for(@case, "requests")
    else
      flash.alert =
        helpers.t "cases.new.correspondence_type_errors.#{valid_type}",
                  type: @correspondence_type_key
      redirect_to new_case_path
    end
  end

  def validate_correspondence_type(ct_abbr)
    ct_exists    = ct_abbr.upcase.in?(CorrespondenceType.pluck(:abbreviation))
    ct_permitted = ct_abbr.upcase.in?(@permitted_correspondence_types.map(&:abbreviation))

    if ct_exists && ct_permitted
      :ok
    elsif !ct_exists
      :unknown
    else
      :not_authorised
    end
  end
end
