#!/bin/sh

ENVIRONMENT=${ENVIRONMENT:-dev}

if [[ -z "${IDENTIFIER}" ]]; then
  echo "Missing environment variable IDENTIFIER"
  exit 1
fi

echo env: ${ENVIRONMENT}
echo identifier: ${IDENTIFIER}

if [[ -z "${DATABASE_HOST}" ]]; then
  echo "Missing environment variable DATABASE_HOST"
  exit 1
fi

if [[ -z "${DATABASE_NAME}" ]]; then
  echo "Missing environment variable DATABASE_NAME"
  exit 1
fi

if [[ -z "${DATABASE_USER}" ]]; then
  echo "Missing environment variable DATABASE_USER"
  exit 1
fi

if [[ -z "${DATABASE_PASSWORD}" ]]; then
  echo "Missing environment variable DATABASE_PASSWORD"
  exit 1
fi

if [[ -z "${S3_BUCKET}" ]]; then
  echo "Missing environment variable S3_BUCKET"
  exit 1
fi

DATE=$(date -u '+%Y-%m-%dT%H-%M-%SZ')
FILENAME=${DATE}-${IDENTIFIER}-${ENVIRONMENT}
DUMP_DIR="/tmp/${FILENAME}"
ARCHIVE_PATH="/tmp/${FILENAME}.tar.gz"
TARGET="s3://${S3_BUCKET}/${FILENAME}.tar.gz"

echo "Backing up ${DATABASE_HOST}/${DATABASE_NAME} to ${TARGET}"

export PGPASSWORD=${DATABASE_PASSWORD}
pg_dump --version
pg_dump --clean -Fd -j 4 --no-acl --no-owner --quote-all-identifiers -v -h "${DATABASE_HOST}" -U "${DATABASE_USER}" -d "${DATABASE_NAME}" --schema=public -f "${DUMP_DIR}"
rc=$?

if [ $rc -ne 0 ]; then
  echo "❌ pg_dump failed"
  export PGPASSWORD=
  exit $rc
fi

echo "Compressing dump directory..."
tar -czf "${ARCHIVE_PATH}" -C /tmp "${FILENAME}"
rc=$?

if [ $rc -ne 0 ]; then
  echo "❌ Compression failed"
  export PGPASSWORD=
  exit $rc
fi

echo "Uploading compressed backup to S3..."
aws s3 cp "${ARCHIVE_PATH}" "${TARGET}"
rc=$?


export PGPASSWORD=

if [ $rc -ne 0 ]; then
  echo "❌ Upload failed"
  exit $rc
fi

# Cleanup local files
rm -rf "${DUMP_DIR}" "${ARCHIVE_PATH}"

echo "✅ Done. Backup pushed to S3: ${TARGET}"

