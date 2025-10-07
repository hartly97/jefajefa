# UI Snippets for Admin Restriction

Hide “New” buttons for non-admins:

```erb
<% if admin? %>
  <%= link_to "New Category", new_category_path, class: "btn btn-primary" %>
<% end %>

<% if admin? %>
  <%= link_to "New Source", new_source_path, class: "btn btn-primary" %>
<% end %>
```
