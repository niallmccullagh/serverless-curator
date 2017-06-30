#!/usr/bin/env bash

set -e

FUNCTION_NAME=CleanElasticSearchIndices
FUNCTION_RUNTIME="python3.6"
FUNCTION_DIST=./dist/elasticsearch-curator.zip
FUNCTION_HANDLER=serverlesscurator.handler
RULE_NAME=Daily
RULE_SCHEDULE="rate(1 day)"

# Check if function exists
if [[ -z "${FUNCTION_ROLE}" ]]; then
  echo "Please set the FUNCTION_ROLE environment variable to the IAM role for executing the function"
  echo "See README for more information."
  exit 1;
fi

# Check if function exists
set +e
aws lambda get-function --function-name $FUNCTION_NAME > /dev/null 2>&1
RESULT=$?
set -e
if [ $RESULT -eq 0 ] ; then
  echo "Function exists"
  # Create or update function configuration
  echo "Updating $FUNCTION_NAME function configuration"
  aws lambda update-function-configuration \
    --function-name $FUNCTION_NAME \
    --runtime $FUNCTION_RUNTIME \
    --role $FUNCTION_ROLE \
    --handler $FUNCTION_HANDLER
  echo "Updated $FUNCTION_NAME function configuration"

  # Update function code
  echo "Deploying $FUNCTION_NAME with $FUNCTION_DIST"
  FUNCTION_ARN=$( \
      aws lambda update-function-code \
          --function-name $FUNCTION_NAME \
          --zip-file fileb://$FUNCTION_DIST \
      | jq --raw-output ".FunctionArn" \
  )
else
  echo "Function does not exist"
  # Create or update function code
  FUNCTION_ARN=$( \
    aws lambda create-function \
      --function-name $FUNCTION_NAME \
      --runtime $FUNCTION_RUNTIME \
      --role $FUNCTION_ROLE \
      --handler $FUNCTION_HANDLER \
      --zip-file fileb://$FUNCTION_DIST \
    | jq --raw-output ".FunctionArn" \
  )
fi

echo "Deployed function: $FUNCTION_ARN"

# Create rule that will triggers function
echo "Creating $RULE_NAME rule"
RULE_ARN=$( \
    aws events put-rule \
        --name "$RULE_NAME" \
        --schedule-expression "$RULE_SCHEDULE" \
        --state ENABLED \
    | \
    jq --raw-output ".RuleArn" \
)
echo "Created rule: $RULE_ARN"

# Remove permission - Can't create if already exists
echo "Attempting to delete permission for rule: $RULE_NAME to target $FUNCTION_NAME"
set +e
aws lambda remove-permission \
  --function-name $FUNCTION_NAME \
  --statement-id "$FUNCTION_NAME-$RULE_NAME"
set -e

# Create permission for rule to execute function-name
echo "Adding permissions for rule: $RULE_NAME to target $FUNCTION_NAME"
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id "$FUNCTION_NAME-$RULE_NAME" \
    --action 'lambda:InvokeFunction' \
    --principal events.amazonaws.com \
    --source-arn $RULE_ARN
echo "Permissions added"

# Add function to rule target so that it fires when the rule triggers
echo "Adding target from rule $RULE_NAME to function $FUNCTION_NAME"
aws events put-targets --rule $RULE_NAME --targets "[
        {
            \"Id\": \"1\",
            \"Arn\": \"$FUNCTION_ARN\"
        }
    ]"
echo "Done"
