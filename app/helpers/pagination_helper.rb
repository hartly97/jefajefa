# app/helpers/pagination_helper.rb
require "will_paginate/view_helpers/action_view"  # make sure ActionView bits are loaded

module PaginationHelper
  class BootstrapLinkRenderer < ::WillPaginate::ActionView::LinkRenderer
    # Wrap in <nav> for a11y
    def html_container(html)
      @template.content_tag(
        :nav,
        @template.content_tag(:ul, html, class: "pagination justify-content-center mt-4"),
        aria: { label: "Pagination" }
      )
    end

    # Numbered pages
    def page_number(page)
      classes = "page-item"
      classes << " active" if page == current_page
      @template.content_tag(
        :li,
        link(page, page, rel: rel_value(page), class: "page-link"),
        class: classes
      )
    end

    # Prev / Next
    def previous_or_next_page(page, text, classname)
      li_class = "page-item"
      li_class << " disabled" unless page
      @template.content_tag(
        :li,
        link(text, page || "#", class: "page-link", aria: { disabled: (!page).to_s }),
        class: li_class
      )
    end

    # Ellipsis
    def gap
      @template.content_tag(
        :li,
        @template.content_tag(:span, "…", class: "page-link"),
        class: "page-item disabled"
      )
    end
  end

  # convenience wrapper (optional)
  def paginate(collection, **opts)
    return unless collection.respond_to?(:total_pages) && collection.total_pages.to_i > 1
    will_paginate(collection, { renderer: BootstrapLinkRenderer }.merge(opts))
  end
end
