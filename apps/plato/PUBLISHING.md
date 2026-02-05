# Publishing Guide

This guide walks through publishing the Plato package to Hex.pm.

## Pre-publish Checklist

- [x] All tests passing (142 tests)
- [x] README.md with installation and usage instructions
- [x] CHANGELOG.md updated with version changes
- [x] LICENSE file present
- [x] mix.exs version updated (currently 0.0.7)
- [x] mix.exs package metadata complete
- [x] Documentation built and reviewed

## Publishing Steps

### 1. Run Tests

```bash
cd apps/plato
docker-compose -f docker-compose.test.yml up -d
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
mix test
```

All 142 tests should pass.

### 2. Build Documentation

```bash
mix docs
```

Review the generated documentation in `doc/index.html`.

### 3. Verify Package Contents

```bash
mix hex.build
```

This creates a tarball and shows what files will be included. Verify:
- lib/ directory
- priv/ directory (migrations)
- README.md
- LICENSE
- CHANGELOG.md
- mix.exs
- .formatter.exs

### 4. Publish to Hex

```bash
mix hex.publish
```

You'll be prompted to:
1. Confirm package contents
2. Confirm version (0.0.7)
3. Enter your Hex credentials
4. Confirm publication

### 5. Verify Publication

After publishing:
1. Visit https://hex.pm/packages/plato
2. Check documentation at https://hexdocs.pm/plato
3. Test installation in a new project:

```elixir
def deps do
  [
    {:plato, "~> 0.0.7"}
  ]
end
```

## Version Bumping

When releasing a new version:

1. Update version in `mix.exs`
2. Update CHANGELOG.md with changes
3. Update `source_ref` in docs section of `mix.exs`
4. Commit changes
5. Tag release: `git tag v0.0.8`
6. Push tags: `git push --tags`
7. Follow publishing steps above

## Troubleshooting

### Authentication Issues

If you haven't authenticated with Hex:

```bash
mix hex.user auth
```

### Package Name Conflicts

If the package name is taken, update in `mix.exs`:

```elixir
defp package do
  [
    name: "plato_cms",  # Alternative name
    # ...
  ]
end
```

### Missing Files

If files are missing from the package, add them to the `files` list in `mix.exs`:

```elixir
files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
```

## Post-Publication

1. Announce on Elixir Forum
2. Update GitHub README with Hex badge
3. Add to Awesome Elixir list
4. Share on social media
