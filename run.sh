#!/bin/bash
# Run the Task Tracker app on Linux desktop

cd "$(dirname "$0")"

echo "Running Project & SLA Task Tracker on Linux..."
echo "Press Ctrl+C to stop the app"
echo ""

flutter run -d linux
