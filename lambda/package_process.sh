#!/bin/bash
set -e  # Exit immediately if any command fails

echo "=== Cleaning up old Process Lambda package ==="
rm -rf process_package process_lambda.zip

echo "=== Creating new process_package/ directory ==="
mkdir process_package

echo "=== Adding process_transcription_lambda.py into process_package/ ==="
cp process_transcription_lambda.py process_package/

echo "=== Zipping the process_package/ into process_lambda.zip ==="
cd process_package
zip -r ../process_lambda.zip .
cd ..

echo "=== Process Lambda package (process_lambda.zip) created successfully ==="
