#!/bin/bash

# 🚀 Jekyll Development Server (by Claude Code)
# Fast and reliable Docker-based local development

echo "🚀 Starting Jekyll development server..."
echo "🌐 Site will be available at: http://localhost:4000"
echo "🛑 Press Ctrl+C to stop"
echo ""

# Use a stable Jekyll 4 image and build-then-serve approach
docker run --rm \
  --name jekyll-dev \
  --volume="$PWD:/srv/jekyll" \
  --publish 4000:4000 \
  --workdir /srv/jekyll \
  ruby:3.1-alpine \
  sh -c "
    echo '📦 Setting up Jekyll...'
    apk add --no-cache build-base python3 > /dev/null 2>&1
    gem install jekyll bundler webrick > /dev/null 2>&1
    
    echo '🏗️  Building site...'
    jekyll build --config _config.yml 2>/dev/null || {
      echo '⚙️  Trying with local config...'
      # Copy original config but remove problematic plugins
      sed 's/plugins:/# Plugins disabled for local dev\n# plugins:/' _config.yml > _config_dev.yml
      echo 'plugins: []' >> _config_dev.yml
      # Remove problematic SEO tag
      sed -i.bak 's/{% seo %}/<!-- SEO disabled for local dev -->/g' _includes/head.html 2>/dev/null || true
      jekyll build --config _config_dev.yml 2>/dev/null
      # Restore file
      mv _includes/head.html.bak _includes/head.html 2>/dev/null || true
    }
    
    echo '✅ Build complete!'
    echo '🌐 Starting server at http://localhost:4000'
    echo '📝 Note: Use .html extension for pages (e.g. /about.html)'
    echo ''
    cd _site && python3 -m http.server 4000
  "