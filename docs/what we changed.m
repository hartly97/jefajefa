Quick recap of what we changed/fixed

Involvements (polymorphic)

Articles are not involvable.

Ran a migration (TidyInvolvementsConstraints) that:

deletes any involvable_type = 'Article' rows,

keeps one canonical unique index on (participant_type, participant_id, involvable_type, involvable_id),

consolidates checks and excludes "Article".

Model guards on Involvement to match DB (only Soldier ↔ War|Battle|Cemetery).

Associations

War and Battle keep has_many :soldiers, through: :involvements.

Article has no connection to Soldier/Involvement.

Citations UI (nested)

citations/_sections.html.erb uses f and yields cf.

citations/_fields.html.erb uses cf (and sf inside cf.fields_for :source).

Stimulus controllers: citations (add/remove) + source_picker.

Censuses

One search form (removed the nested form issue).

display_image_url prefers SmugMug external_image_url, falls back to ActiveStorage if present.

Pagination (will_paginate)

Add initializer requiring will_paginate/view_helpers/action_view.

Optional PaginationHelper::BootstrapLinkRenderer.

Use <%= paginate @collection %>.

Console one-liners

War.first.soldiers.pluck(:last_name)

Battle.first.soldiers.pluck(:last_name)

Sources/citations queries, census entry household lookups, etc. (all in the doc below).

Download

Cheat sheet (routes, forms, console snippets, pagination, images, etc.):
ENDICOTT_APP_COMMANDS.md