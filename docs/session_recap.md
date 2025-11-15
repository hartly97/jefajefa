What’s inside:
See zip download

app/models/

involvement.rb (polymorphic guards + validations)

article.rb (no involvements)

war.rb / battle.rb (soldiers through involvements)

app/views/citations/

_sections.html.erb (uses f → cf)

_fields.html.erb (uses cf; nested sf for new source; Stimulus hooks)

app/views/censuses/

_search.html.erb (single, fixed filter form)

_external_image_fields.html.erb (SmugMug URL + live preview)

app/javascript/controllers/

citations_controller.js (add/remove nested)

source_picker_controller.js (autocomplete/select recent/new source)

app/helpers/pagination_helper.rb (Bootstrap renderer + paginate helper)

config/initializers/will_paginate.rb (required requires 🙂)

db/migrate/20251005023705_tidy_involvements_constraints.rb (clean version)

ENDICOTT_APP_COMMANDS.md (the cheat sheet)