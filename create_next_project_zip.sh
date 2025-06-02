#!/bin/bash

# Setze den relativen Pfad zur types.yml-Datei
types_file="services/types.yml"

# Finde aktuelle höchste Patch-Version
latest_patch=$(ls project_*.zip 2>/dev/null | \
  grep -Eo 'project_[0-9]+\.[0-9]+\.[0-9]+\.zip' | \
  sed -E 's/project_([0-9]+\.[0-9]+\.)([0-9]+)\.zip/\2 \1/' | \
  sort -n | tail -n1)

# Berechne nächste Version
if [ -z "$latest_patch" ]; then
  next_version="0.0.1"
else
  patch=$(echo "$latest_patch" | cut -d' ' -f1)
  prefix=$(echo "$latest_patch" | cut -d' ' -f2)
  next_patch=$((patch + 1))
  next_version="${prefix}${next_patch}"
fi

zip_file="project_${next_version}.zip"

# Sicherheitscheck
if [ -f "$zip_file" ]; then
  echo "❌ Datei $zip_file existiert bereits. Abbruch."
  exit 1
fi

# Update template_version
if [ -f "$types_file" ]; then
  echo "🔧 Updating template_version in $types_file to $next_version ..."
  sed -i.bak -E "s/(template_version: )[0-9]+\.[0-9]+\.[0-9]+/\1$next_version/" "$types_file"
else
  echo "❌ Datei $types_file nicht gefunden. Abbruch."
  exit 1
fi

# Temporäre Struktur erstellen
tmp_dir=".zip_staging"
rm -rf "$tmp_dir"
mkdir -p "$tmp_dir"

cp services/types.yml "$tmp_dir/types.yml"
cp -r services/images "$tmp_dir/images"
cp -r services/playbooks "$tmp_dir/playbooks"

echo "📦 Creating $zip_file ..."

# Wechsle in das staging-Verzeichnis und zippe Inhalt
(
  cd "$tmp_dir"
  zip -r "../$zip_file" . \
    -x "*.bak" \
    -x "*.DS_Store" \
    -x "*.pyc" \
    -x "__pycache__/*" \
    -x "*.swp"
)

# Aufräumen
rm -rf "$tmp_dir"

echo "✅ Created $zip_file."