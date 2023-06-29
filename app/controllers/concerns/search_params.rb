module SearchParams
  extend ActiveSupport::Concern

  def search_params
    permitted_params = params.fetch(:search_query, {}).permit(
      :search_text,
      :parent_id,
    )
    SearchQuery.filter_classes.each do |filter_class|
      permitted_params.merge!(filter_class.set_params(params.fetch(:search_query, {})))
    end
    permitted_params
  end
end
