module TranslateForCase
  class << self
    def translate(kase_or_klass, path, key, **options)
      translator = options.fetch(:translator, I18n.public_method(:t))

      klass = if kase_or_klass.is_a? Class
                kase_or_klass
              elsif kase_or_klass.respond_to?(:decorated?) && kase_or_klass.decorated?
                kase_or_klass.object.class
              else
                kase_or_klass.class
              end
      translation_paths = get_translation_paths(klass.to_s.underscore)

      default = translation_paths
                  .map { |case_path| :"#{path}.#{case_path}.#{key}" }
                  .concat([:"#{path}.#{key}"])
      translator.call(default.shift, **options.merge(default:))
    end

    alias_method :t, :translate

  private

    def get_translation_paths(case_type)
      case_type_segments = case_type.split("/")
      paths = []
      while case_type_segments.any?
        paths << case_type_segments.join("/")
        case_type_segments.pop
      end
      paths
    end
  end
end
