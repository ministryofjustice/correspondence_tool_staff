# <div class="grid-row">
#   <div class="column-two-thirds">
#     <header role="banner">
#       <h1 class="page-heading">
#         <!-- OPTIONAL -->
#         <span class="page-heading--secondary">
#           Hello
#         </span>
#         <span class="page-heading--primary">
#           World
#         </span>
#       </h1>
#     </header>
#   </div>
# </div>

module PageObjects
  module Pages
    module Partials
      class HeaderPartial < SitePrism::Page
        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"
      end
    end
  end
end
