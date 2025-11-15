/.vscode/snippets/rails.json
{
  "ERB Partial Render (with locals)": {
    "prefix": "erbrender",
    "body": [
      "<%= render \"$1\", $2: $3 %>"
    ],
    "description": "Render a partial with locals"
  },

  "ERB Partial Skeleton": {
    "prefix": "erbpartial",
    "body": [
      "<% # locals: ${1:things}: [] %>",
      "<% ${1:things} = local_assigns.fetch(:${1:things}, []) %>",
      "",
      "<% if ${1:things}.blank? %>",
      "  <div class=\"alert alert-light border\">No ${1:things}.</div>",
      "<% else %>",
      "  <div class=\"table-responsive\">",
      "    <table class=\"table table-sm align-middle\">",
      "      <thead>",
      "        <tr>",
      "          <th>${2:Column}</th>",
      "        </tr>",
      "      </thead>",
      "      <tbody>",
      "        <% ${1:things}.each do |${3:thing}| %>",
      "          <tr>",
      "            <td><%= ${3:thing} %></td>",
      "          </tr>",
      "        <% end %>",
      "      </tbody>",
      "    </table>",
      "  </div>",
      "<% end %>"
    ],
    "description": "Basic ERB partial with locals guard"
  },

  "Rails Model (minimal)": {
    "prefix": "railsmodel",
    "body": [
      "class ${TM_FILENAME_BASE/(.*)/${1:/capitalize}/} < ApplicationRecord",
      "  # associations",
      "  # validations",
      "  # scopes",
      "",
      "  # def display_name",
      "  #   (respond_to?(:name) && name.presence) || \"${TM_FILENAME_BASE}\"",
      "  # end",
      "end"
    ],
    "description": "Minimal Rails model skeleton"
  },

  "Rails Controller (index/show)": {
    "prefix": "railscontrollerbasic",
    "body": [
      "class ${TM_FILENAME_BASE/(.*)/${1:/capitalize}/} < ApplicationController",
      "  def index",
      "    @${2:items} = ${3:Model}.order(:id).limit(100)",
      "  end",
      "",
      "  def show",
      "    @${4:item} = ${3:Model}.find_by(slug: params[:id]) || ${3:Model}.find(params[:id])",
      "  end",
      "end"
    ],
    "description": "Simple index/show controller"
  },

  "Stimulus Controller": {
    "prefix": "stimulus",
    "body": [
      "import { Controller } from \"@hotwired/stimulus\"",
      "",
      "export default class extends Controller {",
      "  static targets = [${1:\"list\", \"template\"}]",
      "  static values  = { ${2:index}: Number }",
      "",
      "  connect() {",
      "    // console.log(\"${TM_FILENAME_BASE} connected\")",
      "  }",
      "",
      "  ${3:action}() {",
      "    // TODO",
      "  }",
      "}"
    ],
    "description": "Stimulus controller boilerplate"
  }
}
