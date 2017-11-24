class GlobalNavManager
  class Tab < Page
    attr_reader :name, :parent

    def initialize(name, parent, attrs)
      @name        = name
      @parent      = parent
      @path        = attrs[:path] || name.to_s
      process_scope attrs[:scope] if attrs[:scope].present?
      process_visibility attrs[:visibility]
    end

    def fullpath
      @fullpath ||= File.join(@parent.path, @path)
    end
  end
end
