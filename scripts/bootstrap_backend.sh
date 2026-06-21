#!/usr/bin/env bash
set -euo pipefail

BUCKET="${1:-}"
REGION="${2:-us-east-1}"

if [ -z "${BUCKET}" ]; then
  echo "Usage: $0 <s3-bucket-name> [region]"
  exit 1
fi

echo "Ensuring S3 bucket ${BUCKET} exists in ${REGION}"
if aws s3api head-bucket --bucket "${BUCKET}" 2>/dev/null; then
  echo "Bucket exists"
else
  if [ "${REGION}" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}"
  else
    aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}" --create-bucket-configuration LocationConstraint="${REGION}"
  fi
  aws s3api put-public-access-block --bucket "${BUCKET}" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  aws s3api put-bucket-versioning --bucket "${BUCKET}" --versioning-configuration Status=Enabled
  echo "Created bucket ${BUCKET}"
fi

echo "Backend bootstrap complete (using S3 native lockfile)"
