@echo off
cd C:\OpenFaith-Flutter\openfaith_app
flutter build apk --release > build_output.txt 2>&1
echo EXIT_CODE=%ERRORLEVEL% >> build_output.txt
