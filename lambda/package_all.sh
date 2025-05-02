#!/bin/bash
set -e

echo "Starting Lambda packaging process..."

# ---------- Upload Lambda ----------
echo "Packaging upload lambda..."

rm -rf upload_package
mkdir upload_package

pip install -r requirements.txt -t upload_package/
cp lambda_function.py upload_package/

cd upload_package
zip -r ../../terraform/lambda.zip .
cd ..

echo "lambda.zip created at terraform/lambda.zip"

# ---------- Process Lambda ----------
echo "Packaging process_transcription lambda..."

rm -rf process_package
mkdir process_package

cp process_transcription_lambda.py process_package/

cd process_package
zip -r ../../terraform/process_lambda.zip .
cd ..

echo "process_lambda.zip created at terraform/process_lambda.zip"

echo "Packaging get_transcription_lambda..."

rm -rf get_package
mkdir get_package

cp get_transcription_lambda.py get_package/

cd get_package
zip -r ../../terraform/get_transcription_lambda.zip .
cd ..

echo "get_transcription_lambda.zip created at terraform/get_transcription_lambda.zip"

echo "Done! Lambda functions packaged successfully."
