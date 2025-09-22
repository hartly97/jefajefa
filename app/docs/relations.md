You actually don’t need accepts_nested_attributes_for :source in Citation — and here’s why:

You already have accepts_nested_attributes_for :citations in the Citable concern. That’s what allows you to pass nested citation data from an Article or Soldier form.

Inside each citation block (fields_for :citations), you’re also nesting source_attributes. Rails will happily pass those down to the Citation → belongs_to :source association, as long as you declare it on the parent model (Article/Soldier) instead of on Citation.

If you put accepts_nested_attributes_for :source on Citation, you’re effectively saying “a citation manages its own nested source form”. But you already cover that through the top-level models, so you’d be duplicating the behavior.

The correct pattern here:
class Article < ApplicationRecord
  include Citable
  accepts_nested_attributes_for :citations,
    allow_destroy: true,
    reject_if: :all_blank
end

class Citation < ApplicationRecord
  belongs_to :source, inverse_of: :citations
  belongs_to :citable, polymorphic: true
  validates :source, presence: true
end

TL;DR

✅ Keep accepts_nested_attributes_for :citations in Article (and Soldier).
❌ Don’t add accepts_nested_attributes_for :source in Citation.

That way, your nested forms like this will keep working correctly:

<%= f.fields_for :citations do |cf| %>
  <%= cf.collection_select :source_id, Source.order(:title), :id, :title %>
  <%= cf.fields_for :source do |sf| %>
    <%= sf.text_field :title %>
    <%= sf.text_field :author %>
  <% end %>
<% end %>


Do you want me to go through your Citation model and the Citable concern as they exist now and show you the minimal clean version to avoid conflicts?