defmodule PlatoWeb.SchemaHTML do
  use PlatoWeb, :html

  def index(assigns) do
    ~H"""
    <div class="container">
      <h1>Create a New Schema</h1>

      <form action="/" method="post">
        <div class="form-group">
          <label for="schema_name">
            Schema Name:
          </label>
          <input
            type="text"
            id="schema_name"
            name="schema[name]"
            required
          />
        </div>

        <button type="submit">
          Create Schema
        </button>
      </form>
    </div>
    """
  end
end
