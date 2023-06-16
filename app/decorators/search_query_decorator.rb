class SearchQueryDecorator < Draper::Decorator
  delegate_all

  def user_roles
    object.user.roles.join " "
  end

  def search_query_details
    prettify(object.query.reject do |name, values|
      values.blank? || name == "common_exemption_ids"
    end)
  end

  def list_query_details
    object.query["list_path"].split("/").join(" ").humanize
  end

  def filtered_list_query_details
    prettify(object.query.reject do |name, values|
      values.blank? || name == "list_path"
    end)
  end

private

  def prettify(applied_filters)
    applied_filters.map { |key, value| "#{key.humanize}: #{find_from_id(key, value)}" }.join("</br>").html_safe
  end

  def find_from_id(key, value)
    if key == "filter_assigned_to_ids"
      value.map { |id| Team.find(id).name.to_s }.join " "
    elsif key == "exemption_ids"
      value.map { |id| CaseClosure::Metadatum.exemption_filter_abbreviation(id).to_s }.join ""
    else
      value.is_a?(Array) ? value.join(", ").humanize : value
    end
  end
end
