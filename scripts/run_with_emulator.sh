#!/usr/bin/env zsh
# Run the app on Android emulator with Firestore emulator flag
# Requires: an Android emulator running (flutter devices should list it)
# Usage: ./scripts/run_with_emulator.sh

flutter run -d emulator-5554 --dart-define=USE_FIRESTORE_EMULATOR=true
