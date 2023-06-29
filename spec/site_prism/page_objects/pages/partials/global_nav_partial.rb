# <nav class="global-nav">
#   <ul>
#     <li class="global-nav-item">
#       <a class="" href="/cases">Cases</a>
#     </li>
#     <li class="global-nav-item">
#       <a class="" href="/cases/closed">Closed Cases</a>
#     </li>
#   </ul>
# </nav>
#

module PageObjects
  module Pages
    module Partials
      class GlobalNavPartial < SitePrism::Page
        section :global_nav, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"
      end
    end
  end
end
