class GlobalNavManager
  class Tab < Page
    attr_reader :name, :parent

    def initialize(name, global_nav, parent, attrs)
      @name        = name
      @global_nav  = global_nav
      @parent      = parent
      @path        = attrs[:path] || name.to_s
      @filters     = parent.filters + (attrs[:filter] ? [attrs[:filter]] : [])
      process_visibility attrs[:visibility]
    end

    def fullpath
      @fullpath ||= File.join(@parent.path, @path)
    end
  end
end
