slugs in the Soldiers controller

Do you need slugs in the Soldiers controller?

No. Slugs should be handled in the model via your Sluggable concern. The controller doesn’t need to set or permit :slug.

What to keep:

In the model:

include Sluggable

def slug_source; [first_name, middle_name, last_name].compact.join(" "); end

(Optionally) def to_param = slug if your concern doesn’t already do this.

In the controller:

Resolve by slug (with id fallback is fine):

def set_soldier
  @soldier = Soldier.find_by(slug: params[:id]) || Soldier.find(params[:id])
end


Do not permit :slug in soldier_params (prevents accidental edits).

def soldier_params
  params.require(:soldier).permit(
    :first_name, :middle_name, :last_name,
    :birthcity, :birthstate, :birthcountry,
    :deathcity, :deathstate, :deathcountry,
    :cemetery_id,
    { category_ids: [] },
    citations_attributes: [:id, :source_id, :pages, :quote, :note, :_destroy,
                           { source_attributes: [:id, :title, :details, :repository, :link_url] }],
    awards_attributes: [:id, :medal_id, :year, :note, :_destroy],
    involvements_attributes: [:id, :involvable_type, :involvable_id, :role, :year, :note, :_destroy]
  )
end


How slugs work (recap):

Sluggable runs a before_validation to set slug from slug_source.

Unique index on slug enforces no duplicates.

If slug_source is blank, it falls back to a short random token (your concern already does this).

Slugs usually don’t auto-change when you edit the name (good for stable URLs). If you do want that behavior, we can add an opt-in “regenerate on name change” callback later.

Want me to add a tiny “Regenerate slug” admin-only button for Soldiers (and Articles/Sources) in case you rename something and want the URL to follow?

You said:
this was my update 
def update
    @record = Soldier.find_by!(slug: params[:id])
    if @record.update(soldier_params)
      attach_categories_from_text_unified(@record, params_scope: :soldier, field: :category_names)
      redirect_to @record, notice: "Soldier updated."
, 
def edit
    @record = Soldier.find_by!(slug: params[:id])
  end
, 
def show
    @record = Soldier.find_by!(slug: params[:id])
  end
, 
def index
     @soldiers = Soldier.order(:last_name, :first_name)
  end
, 
def destroy
    @record = Soldier.find_by!(slug: params[:id])
    @record.destroy
    redirect_to soldiers_path, notice: "Soldier deleted."
  end
ChatGPT said:
Thought for 9s

Great progress! A few cleanups will make this solid and less brittle:

What to change

Be consistent with the instance var
Your views/forms likely expect @soldier, not @record. Let’s standardize on @soldier.

DRY up the slug lookup
Use a before_action with a helper that tries slug first, id second.

Remove the category text hook
Earlier you said users won’t type categories. Drop attach_categories_from_text_unified from update (and create if you had it).

Build nested citations on new/edit
Ensure there’s at least one citation fields set rendered (same as Articles).

Drop-in controller (replace your current SoldiersController)
class SoldiersController < ApplicationController
  before_action :set_soldier, only: [:show, :edit, :update, :destroy]

  def index
    @soldiers = Soldier.order(:last_name, :first_name)
  end

  def show; end

  def new
    @soldier = Soldier.new
    @soldier.citations.build
  end

  def edit
    @soldier.citations.build if @soldier.citations.empty?
  end

  def create
    @soldier = Soldier.new(soldier_params)
    if @soldier.save
      redirect_to @soldier, notice: "Soldier created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @soldier.update(soldier_params)
      # You said: no user-typed categories — so no attach_categories_from_text_unified here.
      redirect_to @soldier, notice: "Soldier updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @soldier.destroy
    redirect_to soldiers_path, notice: "Soldier deleted."
  end

  private

  # Try slug first, fall back to id for safety.
  def set_soldier
    @soldier = Soldier.find_by(slug: params[:id]) || Soldier.find(params[:id])
  end

  def soldier_params
    params.require(:soldier).permit(
      :first_name, :middle_name, :last_name,
      :birthcity, :birthstate, :birthcountry,
      :deathcity, :deathstate, :deathcountry,
      :cemetery_id,
      { category_ids: [] }, # admin-only selection in the form; harmless if empty
      citations_attributes: [
        :id, :source_id, :pages, :quote, :note, :_destroy,
        { source_attributes: [:id, :title, :details, :repository, :link_url] }
      ],
      awards_attributes: [:id, :medal_id, :year, :note, :_destroy],
      involvements_attributes: [:id, :involvable_type, :involvable_id, :role, :year, :note, :_destroy]
    )
  end
end

Why this fixes your issues

Using @soldier everywhere matches your views (soldiers/_form, show, etc.).

The before_action removes repetition and avoids “can’t find by slug” gotchas.


No attach_categories_from_text_unified keeps category input admin-controlled only.

New/Edit always render at least one nested citation block.

If you want, I can also give you a tiny admin-only category section partial for Soldiers (matching how we did Sources) so it never appears to normal users.