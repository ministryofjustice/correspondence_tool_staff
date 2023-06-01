module TranslateForCase
  class << self
    def translate(kase_or_klass, path, key, **options)
      translator = options.fetch(:translator, I18n.public_method(:t))

      if kase_or_klass.is_a? Class
        klass = kase_or_klass
      elsif kase_or_klass.respond_to?(:decorated?) && kase_or_klass.decorated?
        klass = kase_or_klass.object.class
      else
        klass = kase_or_klass.class
      end
      translation_paths = get_translation_paths(klass.to_s.underscore)
      default = translation_paths
                  .map { |case_path| :"#{path}.#{case_path}.#{key}" }
                  .concat([:"#{path}.#{key}"])
      translator.call(default.shift, **options.merge(default: default))
    end

    alias t translate

    private

    def get_translation_paths(case_type)
      case_type_segments = case_type.split("/")
      paths = []
      while case_type_segments.any?
        paths << case_type_segments.join("/")
        case_type_segments.pop
      end
      return paths
    end
  end
end
