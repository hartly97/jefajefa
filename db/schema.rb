# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_11_15_101653) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.string "title", null: false
    t.text "body"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.string "author"
    t.datetime "date"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
  end

  create_table "awards", force: :cascade do |t|
    t.string "name"
    t.string "country"
    t.bigint "soldier_id", null: false
    t.integer "year"
    t.text "note"
    t.string "slug"
    t.index "lower((slug)::text)", name: "idx_awards_lower_slug", unique: true
    t.index "lower((slug)::text)", name: "index_awards_on_lower_slug", unique: true
    t.index "soldier_id, lower((name)::text), year", name: "index_awards_on_soldier_name_year", unique: true, where: "((name IS NOT NULL) AND (btrim((name)::text) <> ''::text))"
    t.index ["slug"], name: "index_awards_on_slug", unique: true
    t.index ["soldier_id"], name: "index_awards_on_soldier_id"
  end

  create_table "battles", force: :cascade do |t|
    t.string "name", null: false
    t.date "date"
    t.string "slug", null: false
    t.bigint "war_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((slug)::text)", name: "index_battles_on_lower_slug", unique: true
    t.index ["slug"], name: "index_battles_on_slug", unique: true
    t.index ["war_id"], name: "index_battles_on_war_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "name"
    t.string "page_number"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transcription"
    t.string "transcriptiontwo"
    t.index ["name"], name: "index_books_on_name"
  end

  create_table "burials", force: :cascade do |t|
    t.bigint "cemetery_id", null: false
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "participant_type"
    t.bigint "participant_id"
    t.date "birth_date"
    t.string "birth_place"
    t.date "death_date"
    t.string "death_place"
    t.text "inscription"
    t.string "section"
    t.string "plot"
    t.string "marker"
    t.string "link_url"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.bigint "soldier_id"
    t.index "lower((slug)::text)", name: "idx_burials_lower_slug", unique: true
    t.index "lower((slug)::text)", name: "indexes_burials_on_lower_slug", unique: true
    t.index ["cemetery_id", "participant_type", "participant_id"], name: "idx_burials_unique_triplet", unique: true
    t.index ["cemetery_id"], name: "index_burials_on_cemetery_id"
    t.index ["participant_type", "participant_id"], name: "index_burials_on_participant_type_and_participant_id"
    t.index ["soldier_id"], name: "index_burials_on_soldier_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "category_type"
    t.text "description"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "idx_categories_lower_name"
    t.index "lower((slug)::text)", name: "idx_categories_lower_slug", unique: true
    t.index "lower((slug)::text)", name: "indexes_categories_on_lower_slug", unique: true
    t.index ["category_type", "name"], name: "index_categories_on_category_type_and_name"
    t.index ["name", "category_type"], name: "index_categories_on_name_and_category_type", unique: true
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "categorizations", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "categorizable_type", null: false
    t.bigint "categorizable_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["categorizable_type", "categorizable_id", "category_id"], name: "index_categorizations_on_poly_and_category", unique: true
    t.index ["categorizable_type", "categorizable_id"], name: "index_categorizations_on_categorizable"
    t.index ["category_id", "categorizable_type", "categorizable_id"], name: "index_categorizations_on_all", unique: true
    t.index ["category_id"], name: "index_categorizations_on_category_id"
  end

  create_table "cemeteries", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((slug)::text)", name: "idx_cemeteries_lower_slug", unique: true
    t.index "lower((slug)::text)", name: "indexes_cemeteries_on_lower_slug", unique: true
    t.index ["slug"], name: "index_cemeteries_on_slug", unique: true
  end

  create_table "census_entries", force: :cascade do |t|
    t.bigint "census_id", null: false
    t.bigint "soldier_id"
    t.string "householdid"
    t.string "linenumber"
    t.integer "household_position"
    t.string "firstname"
    t.string "lastname"
    t.string "sex"
    t.string "age"
    t.string "relationshiptohead"
    t.string "occupation"
    t.string "birthlikedate"
    t.string "birthlikeplacetext"
    t.string "birthcounty"
    t.string "birthcountry"
    t.string "residencedate"
    t.string "residenceplacetext"
    t.string "residenceplacecounty"
    t.string "residenceplacecountry"
    t.string "location"
    t.string "regnumber"
    t.string "page_ref"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index "lower((slug)::text)", name: "idx_census_entries_lower_slug", unique: true
    t.index ["census_id", "householdid", "linenumber"], name: "idx_census_entries_loc"
    t.index ["census_id"], name: "index_census_entries_on_census_id"
    t.index ["lastname", "firstname"], name: "index_census_entries_on_lastname_and_firstname"
    t.index ["slug"], name: "index_census_entries_on_slug", unique: true, where: "(slug IS NOT NULL)"
    t.index ["soldier_id"], name: "index_census_entries_on_soldier_id"
  end

  create_table "census_imports", force: :cascade do |t|
    t.string "relationshiptohead"
    t.string "firstname"
    t.string "lastname"
    t.string "sex"
    t.string "birthlikedate"
    t.string "birthlikeplacetext"
    t.string "birthcounty"
    t.string "birthcountry"
    t.string "chrdate"
    t.string "chrplacetext"
    t.string "residencedate"
    t.string "location"
    t.string "residenceplacetext"
    t.string "residenceplacecounty"
    t.string "residenceplacecountry"
    t.string "age"
    t.string "householdid"
    t.string "booknumber"
    t.string "linenumber"
    t.string "page"
    t.string "piecefolio"
    t.string "regnumber"
    t.string "marriagelikedate"
    t.string "marriagelikeplacetext"
    t.string "deathlikedate"
    t.string "deathlikeplacetext"
    t.string "burialdate"
    t.string "burialplacetext"
    t.string "fatherfullname"
    t.string "fatherlast"
    t.string "motherfullname"
    t.string "motherlast"
    t.string "spousefullname"
    t.string "spouselast"
    t.string "childrenfullname1"
    t.string "childrenfullname2"
    t.string "childrenfullname3"
    t.string "childrenfullname4"
    t.string "childrenfullname5"
    t.string "childrenfullname6"
    t.string "childrenfullname7"
    t.string "childrenfullname8"
    t.string "childrenfullname9"
    t.string "childrenfullname10"
    t.string "childrenfullname11"
    t.string "childrenfullname12"
    t.string "otherfullname1"
    t.string "otherfullname2"
    t.string "otherfullname3"
    t.string "otherfullname4"
    t.string "otherfullname5"
    t.string "otherfullname6"
    t.string "otherfullname7"
    t.string "otherfullname8"
    t.string "otherfullname9"
    t.string "otherfullname10"
    t.string "otherfullname11"
    t.string "otherfullname12"
    t.string "otherfullname13"
    t.string "otherfullname14"
    t.string "otherfullname15"
    t.string "otherfullname16"
    t.string "otherfullname17"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["firstname"], name: "index_census_imports_on_firstname"
    t.index ["lastname"], name: "index_census_imports_on_lastname"
  end

  create_table "censuses", force: :cascade do |t|
    t.string "country", null: false
    t.integer "year", null: false
    t.string "district"
    t.string "subdistrict"
    t.string "place"
    t.string "piece"
    t.string "folio"
    t.string "page"
    t.string "booknumber"
    t.string "image_url"
    t.string "slug", null: false
    t.bigint "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_image_url"
    t.string "external_image_caption"
    t.string "external_image_credit"
    t.index "lower((slug)::text)", name: "idx_censuses_lower_slug", unique: true
    t.index "lower((slug)::text)", name: "indexes_censuses_on_lower_slug", unique: true
    t.index ["country", "year", "district", "subdistrict", "piece", "folio", "page"], name: "idx_censuses_locator"
    t.index ["slug"], name: "index_censuses_on_slug", unique: true
    t.index ["source_id"], name: "index_censuses_on_source_id"
  end

  create_table "citations", force: :cascade do |t|
    t.bigint "source_id", null: false
    t.string "citable_type", null: false
    t.bigint "citable_id", null: false
    t.string "pages"
    t.text "quote"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "volume"
    t.string "issue"
    t.string "folio"
    t.string "page"
    t.string "column"
    t.string "line_number"
    t.string "record_number"
    t.string "image_url"
    t.string "image_frame"
    t.string "roll"
    t.string "enumeration_district"
    t.string "locator"
    t.index ["citable_type", "citable_id"], name: "index_citations_on_citable_type_and_citable_id"
    t.index ["source_id", "citable_type", "citable_id", "volume", "folio", "page"], name: "idx_citations_locator"
    t.index ["source_id", "citable_type", "citable_id"], name: "index_citations_pair"
    t.index ["source_id"], name: "index_citations_on_source_id"
  end

  create_table "involvements", force: :cascade do |t|
    t.string "participant_type", null: false
    t.bigint "participant_id", null: false
    t.string "involvable_type", null: false
    t.bigint "involvable_id", null: false
    t.string "role"
    t.integer "year"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["involvable_type", "involvable_id"], name: "index_involvements_on_involvable_type_and_involvable_id"
    t.index ["participant_type", "participant_id", "involvable_type", "involvable_id"], name: "idx_involvements_unique_link", unique: true
    t.index ["participant_type", "participant_id"], name: "index_involvements_on_participant_type_and_participant_id"
    t.check_constraint "char_length(COALESCE(role, ''::character varying)::text) <= 100", name: "chk_inv_role_length"
    t.check_constraint "involvable_type::text = ANY (ARRAY['War'::character varying, 'Battle'::character varying, 'Cemetery'::character varying]::text[])", name: "chk_inv_involvable_type"
    t.check_constraint "participant_type::text = 'Soldier'::text", name: "chk_inv_participant_type"
    t.check_constraint "year IS NULL OR year > 0 AND year < 3000", name: "chk_inv_year_range"
  end

  create_table "medals", force: :cascade do |t|
    t.string "name", null: false
    t.integer "year"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((slug)::text)", name: "idx_medals_lower_slug", unique: true
    t.index "lower((slug)::text)", name: "indexes_medals_on_lower_slug", unique: true
    t.index ["slug"], name: "index_medals_on_slug", unique: true
  end

  create_table "newsletters", force: :cascade do |t|
    t.string "volume", null: false
    t.string "number", null: false
    t.string "day", null: false
    t.string "month", null: false
    t.string "year", null: false
    t.string "title", null: false
    t.string "slug", null: false
    t.string "version"
    t.string "content"
    t.string "image"
    t.string "file_name"
    t.index "lower((slug)::text)", name: "idx_newsletters_lower_slug", unique: true
    t.index "lower((slug)::text)", name: "indexes_newsletters_on_lower_slug", unique: true
    t.index ["slug"], name: "index_newsletters_on_slug", unique: true
  end

  create_table "or_patch_soldier_medals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "relations", force: :cascade do |t|
    t.string "from_type", null: false
    t.bigint "from_id", null: false
    t.string "to_type", null: false
    t.bigint "to_id", null: false
    t.string "relation_type", default: "related", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_type", "from_id", "to_type", "to_id", "relation_type"], name: "index_relations_unique", unique: true
    t.index ["from_type", "from_id"], name: "index_relations_on_from_type_and_from_id"
    t.index ["to_type", "to_id"], name: "index_relations_on_to_type_and_to_id"
  end

  create_table "soldier_medals", force: :cascade do |t|
    t.bigint "soldier_id", null: false
    t.bigint "medal_id", null: false
    t.integer "year"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index "lower((slug)::text)", name: "idx_soldier_medals_lower_slug", unique: true
    t.index "lower((slug)::text)", name: "indexes_soldier_medals_on_lower_slug", unique: true
    t.index ["medal_id"], name: "index_soldier_medals_on_medal_id"
    t.index ["soldier_id", "medal_id", "year"], name: "idx_soldier_medals_uniqueish"
    t.index ["soldier_id"], name: "index_soldier_medals_on_soldier_id"
  end

  create_table "soldiers", force: :cascade do |t|
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "birthcity"
    t.string "birthstate"
    t.string "birthcountry"
    t.string "deathcity"
    t.string "deathstate"
    t.string "deathcountry"
    t.bigint "cemetery_id"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "birth_date"
    t.string "death_date"
    t.string "deathplace"
    t.string "birthplace"
    t.string "first_enlisted_start_date"
    t.string "first_enlisted_end_date"
    t.string "first_enlisted_place"
    t.string "branch_of_service"
    t.string "unit"
    t.index "lower((slug)::text)", name: "index_soldiers_on_lower_slug", unique: true
    t.index ["cemetery_id"], name: "index_soldiers_on_cemetery_id"
    t.index ["last_name", "first_name"], name: "index_soldiers_on_last_name_and_first_name"
    t.index ["slug"], name: "index_soldiers_on_slug", unique: true
  end

  create_table "sources", force: :cascade do |t|
    t.string "title", null: false
    t.text "details"
    t.string "repository"
    t.string "link_url"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "author"
    t.string "publisher"
    t.string "year"
    t.string "url"
    t.string "pages"
    t.boolean "common", default: false, null: false
    t.integer "citations_count", default: 0, null: false
    t.index "lower((slug)::text)", name: "indexes_sources_on_lower_slug", unique: true
    t.index ["citations_count"], name: "index_sources_on_citations_count"
    t.index ["common"], name: "index_sources_on_common"
    t.index ["slug"], name: "index_sources_on_slug", unique: true
    t.index ["title"], name: "index_sources_on_title"
  end

  create_table "wars", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((slug)::text)", name: "index_wars_on_lower_slug", unique: true
    t.index ["slug"], name: "index_wars_on_slug", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "awards", "soldiers"
  add_foreign_key "battles", "wars"
  add_foreign_key "burials", "cemeteries"
  add_foreign_key "burials", "soldiers"
  add_foreign_key "categorizations", "categories"
  add_foreign_key "census_entries", "censuses"
  add_foreign_key "census_entries", "soldiers"
  add_foreign_key "censuses", "sources"
  add_foreign_key "citations", "sources"
  add_foreign_key "soldier_medals", "medals"
  add_foreign_key "soldier_medals", "soldiers"
  add_foreign_key "soldiers", "cemeteries"
end
