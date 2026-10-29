# Contributing

Keep changes focused and preserve the ownership boundaries between project sessions, tasks, terminals, and native plugins. Run `flutter analyze`, `flutter test`, and the Python script tests before submitting changes. Native changes also require an Android arm64 build.

## Commits

Use Conventional Commits with an English imperative subject:

```text
feat: add project search
fix: preserve terminal selection
refactor: simplify task ownership
```

Supported types: `feat`, `fix`, `refactor`, `docs`, `test`, `build`, `ci`, and `chore`. An optional scope identifies the affected component, for example `fix(terminal): restore input focus`.

Never commit credentials, signing material, local machine configuration, private service addresses, generated artifacts, or logs containing personal data. Use a GitHub noreply email when authoring commits if your email address is private.

## License

Flit is licensed under the [GNU General Public License v3.0](LICENSE). By submitting a contribution you agree that it is licensed under the same terms.
