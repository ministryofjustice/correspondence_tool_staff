module FormObjectUpdatable
  extend ActiveSupport::Concern

  private

  def update_and_advance(form_class, opts = {}, &block)
    hash = permitted_params(form_class).to_h

    @form_object = form_class.new(
      hash.merge(record: opts[:record])
    )

    if @form_object.save
      block.call(@form_object)
    else
      render opts.fetch(:render, :edit)
    end
  end

  def permitted_params(form_class)
    params
      .fetch(form_class.model_name.singular, {})
      .permit(form_attribute_names(form_class))
  end

  def form_attribute_names(form_class)
    form_class.attribute_types.map do |(attr_name, primitive)|
      primitive.is_a?(ActiveModel::Type::Date) ? date_params(attr_name) : attr_name
    end.flatten
  end

  def date_params(attr_name)
    %W[#{attr_name}_dd #{attr_name}_mm #{attr_name}_yyyy]
  end
end
