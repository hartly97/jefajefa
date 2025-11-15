Great question. Short version:

url = inv.participant_path calls a tiny method on your Involvement that tries to build a link to the participant (e.g., the Soldier).

If it can build a URL (participant still exists and there’s a route), you get a clickable link; if not, it just shows the label as plain text.

Here’s how/where you’d use it.

Where to use that snippet

Anywhere you list involvements, e.g.:

wars/show.html.erb (list soldiers involved in a war)

battles/show.html.erb (list soldiers in a battle)

cemeteries/show.html.erb (if you’re showing soldiers interred via involvements)

soldiers/show.html.erb (if you show the soldier’s battles/wars via involvements)

You can drop this inside any loop over involvements:
<ul class="list-unstyled">
  <% @involvements.each do |inv| %>
    <li>
      <% if (url = inv.participant_path) %>
        <%= link_to inv.participant_label, url %>
      <% else %>
        <%= inv.participant_label %>
      <% end %>
      <%= " — " + content_tag(:strong, inv.role) if inv.role.present? %>
      <%= " (#{inv.year})" if inv.year.present? %>
      <%= " — " + content_tag(:em, inv.note) if inv.note.present? %>
    </li>
  <% end %>
</ul>

Make it reusable (optional)

Create a tiny partial you can reuse anywhere:

app/views/shared/_involvement_list.html.erb

<% involvements = local_assigns.fetch(:involvements, []) %>

<ul class="list-unstyled">
  <% involvements.each do |inv| %>
    <li>
      <% if (url = inv.participant_path) %>
        <%= link_to inv.participant_label, url %>
      <% else %>
        <%= inv.participant_label %>
      <% end %>
      <%= " — " + content_tag(:strong, inv.role) if inv.role.present? %>
      <%= " (#{inv.year})" if inv.year.present? %>
      <%= " — " + content_tag(:em, inv.note) if inv.note.present? %>
    </li>
  <% end %>
</ul>

Then in, say, wars/show.html.erb:
<h2>Involvements</h2>
<%= render "shared/involvement_list", involvements: @war.involvements.includes(:participant).order(:year, :id) %>

def participant_path
  p = participant
  return nil unless p
  Rails.application.routes.url_helpers.polymorphic_path(p) rescue nil
end

polymorphic_path(p) figures out the correct show path for whatever p is (e.g., /soldiers/123, /articles/foo, etc., based on routes).

It returns nil if the participant is missing or there’s no route, so your view falls back to plain text.

Controller hint (helps performance)

When you render involvements, preload participants:

# wars_controller.rb
def show
  @war = War.find(params[:id])
  @involvements = @war.involvements.includes(:participant).order(:year, :id)
end

That’s it! The url = … inside the if is just a Ruby trick: it both assigns the local variable and tests its truthiness so you don’t call participant_path twice.