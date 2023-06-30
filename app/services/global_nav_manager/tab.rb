class GlobalNavManager
  class Tab < Page
    attr_reader :name, :parent, :count

    def initialize(name:, parent:, attrs:)
      super(name:, parent:, attrs:)
      @path = attrs[:path] || name.to_s
      @count = nil
      process_scope attrs[:scope] if attrs[:scope].present?
      process_visibility attrs[:visibility]
    end

    def fullpath
      @fullpath ||= File.join(@parent.path, @path)
    end

    def set_count(value)
      @count = value
    end
  end
end
