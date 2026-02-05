defmodule Mix.Tasks.Plato.Install do
  @moduledoc """
  Installs Plato CMS by copying migrations to your application.

  ## Usage

      mix plato.install

  This will copy all Plato migration files from the library to your
  application's `priv/repo/migrations` directory with updated timestamps.

  After running this task, run migrations:

      mix ecto.migrate
  """

  @shortdoc "Installs Plato CMS migrations"

  use Mix.Task

  @requirements ["app.config"]

  @impl Mix.Task
  def run(_args) do
    app_path = File.cwd!()
    migrations_target = Path.join([app_path, "priv", "repo", "migrations"])

    # Ensure target directory exists
    File.mkdir_p!(migrations_target)

    # Get Plato's migrations directory
    plato_priv = :code.priv_dir(:plato) |> to_string()
    migrations_source = Path.join([plato_priv, "repo", "migrations"])

    case File.ls(migrations_source) do
      {:ok, files} ->
        migration_files = Enum.filter(files, &String.ends_with?(&1, ".exs"))

        if Enum.empty?(migration_files) do
          Mix.shell().info("No migrations found in Plato.")
        else
          copied_count = copy_migrations(migration_files, migrations_source, migrations_target)

          Mix.shell().info([
            :green,
            "\n✓ Successfully copied #{copied_count} migration file(s) to #{migrations_target}\n"
          ])

          Mix.shell().info([
            "\nNext steps:\n",
            "  1. Review the migration in priv/repo/migrations/\n",
            "  2. Run: mix ecto.migrate\n",
            "  3. Configure Plato in your config/config.exs:\n\n",
            "     config :my_app, :plato,\n",
            "       repo: MyApp.Repo\n\n",
            "  4. Mount the admin UI in your router:\n\n",
            "     import Plato.Router\n\n",
            "     scope \"/\" do\n",
            "       pipe_through :browser\n",
            "       plato_admin \"/admin/cms\", otp_app: :my_app\n",
            "     end\n"
          ])
        end

      {:error, reason} ->
        Mix.raise("Could not read Plato migrations: #{inspect(reason)}")
    end
  end

  defp copy_migrations(files, source_dir, target_dir) do
    timestamp = calendar_timestamp()

    files
    |> Enum.with_index()
    |> Enum.map(fn {file, index} ->
      # Extract the original migration name (without timestamp)
      migration_name = String.replace(file, ~r/^\d+_/, "")

      # Create new timestamp (add index to avoid collisions)
      new_timestamp = timestamp + index
      new_filename = "#{new_timestamp}_#{migration_name}"

      source_path = Path.join(source_dir, file)
      target_path = Path.join(target_dir, new_filename)

      # Check if migration already exists (by name, not timestamp)
      existing = find_existing_migration(target_dir, migration_name)

      if existing do
        Mix.shell().info("  Skipping #{migration_name} (already exists as #{existing})")
        nil
      else
        File.cp!(source_path, target_path)
        Mix.shell().info("  Copied #{new_filename}")
        :copied
      end
    end)
    |> Enum.count(&(&1 == :copied))
  end

  defp find_existing_migration(dir, migration_name) do
    case File.ls(dir) do
      {:ok, files} ->
        Enum.find(files, fn file ->
          String.ends_with?(file, migration_name)
        end)

      {:error, _} ->
        nil
    end
  end

  defp calendar_timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
    |> String.to_integer()
  end

  defp pad(i) when i < 10, do: "0#{i}"
  defp pad(i), do: to_string(i)
end
