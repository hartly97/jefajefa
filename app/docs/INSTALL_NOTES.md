# Install Notes — Mega Bundle
Generated: 2025-09-10

This bundle includes:
- Models, controllers, views for Articles, Sources, Soldiers, Categories, Relations
- Seeds (base lookups + 2 example soldiers)
- Reset scripts (db/seeds_reset.rb)
- Admin-only slug regeneration (Sluggable, AdminGuard, controller/view snippets, routes)
- Citations fields partial with author, publisher, year, url

## Steps after unzipping

1. **Install bundle files**
   Unzip directly into your Rails project root. Files are already in their correct `app/`, `config/`, `db/` structure.

2. **Routes**
   Make sure `config/routes.rb` includes:
   ```ruby
   resources :soldiers do
     patch :regenerate_slug, on: :member
   end

   resources :articles do
     patch :regenerate_slug, on: :member
   end

   resources :sources do
     patch :regenerate_slug, on: :member
   end
   ```

3. **Migrate DB**
   ```bash
   bin/rails db:migrate
   ```

4. **Reset + Seed (optional)**
   To clear and reseed soldiers, sources, medals, wars, battles, cemeteries:
   ```bash
   bin/rails runner db/seeds_reset.rb
   bin/rails db:seed
   ```

5. **Slug regeneration**
   - Works on Soldiers, Articles, Sources
   - Button only visible to admins (`current_user&.admin?`)
   - Clicking regenerates slug and redirects to new URL

6. **Citations partial**
   - Use in forms:
     ```erb
     <%= f.fields_for :citations do |cf| %>
       <%= render "citations/fields", f: cf, sources: Source.order(:title) %>
     <% end %>
     ```

7. **Strong params**
   Ensure your controllers permit nested source fields, e.g.:
   ```ruby
   { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
   ```

That’s it — unzip, migrate, seed, and you’re ready.
