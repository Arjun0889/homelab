#!/bin/bash
# Sync adlists from pihole.values.yaml to Pi-hole gravity database
# Run this after adding new adlists to pihole.values.yaml and deploying with helmfile

set -e

echo "🔄 Syncing adlists from /etc/pihole/adlists.list to gravity database..."

kubectl exec -n pihole-system deployment/pihole -- bash -c '
  added=0
  skipped=0
  
  while IFS= read -r url; do
    # Skip empty lines and comments
    [[ -z "$url" || "$url" =~ ^# ]] && continue
    
    # Check if URL already exists
    exists=$(sqlite3 /etc/pihole/gravity.db "SELECT COUNT(*) FROM adlist WHERE address=\"$url\";")
    
    if [ "$exists" -eq 0 ]; then
      echo "  ✓ Adding: $url"
      sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES (\"$url\", 1, \"Added from adlists.list\");"
      ((added++))
    else
      ((skipped++))
    fi
  done < /etc/pihole/adlists.list
  
  echo ""
  echo "📊 Summary:"
  echo "   Added: $added"
  echo "   Already exists: $skipped"
  
  total=$(sqlite3 /etc/pihole/gravity.db "SELECT COUNT(*) FROM adlist;")
  echo "   Total adlists in database: $total"
'

echo ""
echo "🔄 Running gravity update to download new lists..."
kubectl exec -n pihole-system deployment/pihole -- pihole -g

echo ""
echo "✅ Done! Check Pi-hole dashboard for updated statistics."
