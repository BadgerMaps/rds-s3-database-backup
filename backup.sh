#!/bin/sh


ENVIRONMENT=${ENVIRONMENT:-dev}
REGION=${AWS_REGION:-us-east-1}

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
TARGET=s3://${S3_BUCKET}/${DATE}-${IDENTIFIER}-${ENVIRONMENT}.dump.gz

echo "Backing up ${DATABASE_HOST}/${DATABASE_NAME} to ${TARGET}"

export PGPASSWORD=${DATABASE_PASSWORD}
pg_dump -Fc --no-acl --no-owner --quote-all-identifiers -v -h ${DATABASE_HOST} -U ${DATABASE_USER} -d ${DATABASE_NAME} | aws s3 cp - ${TARGET}
rc=$?

# unsets variable for security reasons
export PGPASSWORD=

if [[ $rc != 0 ]]; then exit $rc; fi

echo "Done. Backup pushed to S3. ${TARGET}"
