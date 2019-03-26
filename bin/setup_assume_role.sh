#!/usr/bin/env bash
TMP_FILE=".temp_credentials"
export AWS_PROFILE=default
aws sts assume-role --output json --role-arn ${1} --role-session-name "DIBaselinePlatformAWSK8Pipeline" > ${TMP_FILE} || { echo 'sts failure!' ; exit 1; }


ACCESS_KEY=$(cat ${TMP_FILE} | jq -r ".Credentials.AccessKeyId")
SECRET_KEY=$(cat ${TMP_FILE} | jq -r ".Credentials.SecretAccessKey")
SESSION_TOKEN=$(cat ${TMP_FILE} | jq -r ".Credentials.SessionToken")
EXPIRATION=$(cat ${TMP_FILE} | jq -r ".Credentials.Expiration")


cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id=${ACCESS_KEY}
aws_secret_access_key=${SECRET_KEY}
aws_session_token=${SESSION_TOKEN}
region=us-east-1
EOF
