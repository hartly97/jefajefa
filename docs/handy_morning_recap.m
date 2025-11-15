Boot + routes sanity

bin/rails s

bin/rails routes -g sources (confirm autocomplete_sources is there)

bin/rails routes -g censuses (index/new/show/edit helpers look right)

Censuses UI smoke test (2–3 min)

Visit /censuses

Try the filter form (year/district + free-text).

Click a row → show page

Paste a SmugMug URL into Edit → “Image (External)” and save.

Confirm image renders with caption/credit.

Citations UX quick pass (2–3 min)

On any form using citations:

Add a citation, pick an existing Source from the select.

Try + Add another citation, then Remove (should hide + set :_destroy).

Toggle “Add a new source instead”, type a new Source title, save, and verify it persisted.

Involvements guardrails (console, 1 min)