#!/bin/bash
# -----------------------------------------------------------------
# Pushes sample CPU / Memory / HTTP-availability metrics for the
# abc-website into Graphite using the Carbon plaintext protocol.
#
# Usage:
#   chmod +x push-metrics-to-graphite.sh
#   ./push-metrics-to-graphite.sh <graphite-host> <carbon-port>
#
# Example:
#   ./push-metrics-to-graphite.sh localhost 2003
#
# Run this in a loop (e.g. via cron every minute, or a `while true`
# loop) so Grafana has continuous data to plot.
# -----------------------------------------------------------------

GRAPHITE_HOST="${1:-localhost}"
CARBON_PORT="${2:-2003}"
NOW=$(date +%s)

# Real container CPU/mem could be pulled with: docker stats --no-stream
CPU_USAGE=$(awk 'BEGIN{srand(); print int(10+rand()*40)}')      # simulated %
MEM_USAGE=$(awk 'BEGIN{srand(); print int(100+rand()*300)}')    # simulated MB
HTTP_UP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health.txt)
HTTP_AVAILABLE=0
[ "$HTTP_UP" == "200" ] && HTTP_AVAILABLE=1

METRICS="abc_website.cpu.usage_percent ${CPU_USAGE} ${NOW}
abc_website.memory.usage_mb ${MEM_USAGE} ${NOW}
abc_website.http.available ${HTTP_AVAILABLE} ${NOW}"

echo "$METRICS" | nc -q1 "$GRAPHITE_HOST" "$CARBON_PORT"
echo "Sent metrics at $(date):"
echo "$METRICS"
