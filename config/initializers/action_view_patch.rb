# TO-DO https://dsdmoj.atlassian.net/browse/CT-2780
# remove this file after update to Rails 5.2
# Monkey patch escape JavaScript method to prevent XSS vulnerability
# https://github.com/advisories/GHSA-65cv-r6x7-79hv

ActionView::Helpers::JavaScriptHelper::JS_ESCAPE_MAP.merge!(
  {
    "`" => "\\`",
    "$" => "\\$",
  },
)

module ActionView::Helpers::JavaScriptHelper
  alias_method :old_ej, :escape_javascript
  alias_method :old_j, :j

  def escape_javascript(javascript)
    javascript = javascript.to_s
    result = if javascript.empty?
               ""
             else
               javascript.gsub(/(\\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"']|`|[$])/u, JS_ESCAPE_MAP)
             end
    javascript.html_safe? ? result.html_safe : result
  end

  alias_method :j, :escape_javascript
end
