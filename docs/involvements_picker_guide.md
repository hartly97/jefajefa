# Involvement Picker (AJAX) — How It Works

This flow lets you add Soldier → (War/Battle/Cemetery) involvements via AJAX on the Soldier form.

## Pieces

- **Stimulus controllers**
  - `involvement_picker_controller.js`: controls *type* and *record* selection and writes them into the dataset on the “form box”.
  - `involvement_form_controller.js`: reads those dataset values and POSTs to `/involvements.json`.

- **View**
  - In `app/views/soldiers/_form_fields.html.erb`, one wrapper:
    ```erb
    <div data-controller="involvement-form involvement-picker">
      <div data-involvement-form-target="form"
           data-involvable-type="War"
           data-involvable-id=""
           data-involvement-picker-target="formBox">
      ```
    - The `form` **target** belongs to the `involvement-form` controller.
    - The same element is also `formBox` **target** for the `involvement-picker`.

- **Server**
  - `InvolvementsController#create` handles upsert (unique by participant/involvable), returns JSON.
  - `involvement_json` includes `participant_path` for stable links.

## Smoke Test (DevTools Console)

1. Open the Soldier edit page.
2. Run:
   ```js
   (() => {
     const picker = document.querySelector('[data-controller~="involvement-picker"]')
     const formBox = document.querySelector('[data-involvement-form-target="form"]')
     const type   = formBox?.dataset?.involvableType || "(none)"
     const id     = formBox?.dataset?.involvableId   || "(none)"
     console.log("Type:", type, "Id:", id)
   })()
