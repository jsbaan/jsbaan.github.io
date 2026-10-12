# Local development

```bash
./serve.sh
```

Then open http://localhost:4000. Pages rebuild and the browser reloads automatically when you save a file (changes to `_config.yml` need a restart).

The first run installs gems into `vendor/bundle` (a few minutes); later runs start in seconds.

## How it works

- The `github-pages` gem in the `Gemfile` pins Jekyll and all plugins to the versions GitHub Pages uses, so the local build matches the live site.
- Requires Ruby (tested with 3.3.5) and Bundler. GitHub Pages ignores the `Gemfile`, so deployment is unchanged: push to `master`.
- On macOS, `serve.sh` sets `CPLUS_INCLUDE_PATH` to work around broken C++ headers in some Command Line Tools installs, which otherwise makes the `eventmachine` gem fail to compile.
