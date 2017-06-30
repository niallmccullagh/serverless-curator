# Serverless Curator

An AWS lambda function that runs daily to delete indices in elastic search.

## Configure

### serverless-curator.yaml

* Update the `endpoint` to the elasticsearch cluster endpoint
* Update the `region` to the region that the elasticsearch cluster is in
* Add any indices configuration
** prefixes e.g. `logstash-`
** Days to keep

## Build

Build the lambda function code by running `./build`. This will bundle the required dependencies and
scripts into a distribution.

## Deploying

1. Ensure that you are logged into AWS cli
1. Create a role by following the steps in [Create IAM role for lambda](http://docs.aws.amazon.com/lambda/latest/dg/with-s3-example-create-iam-role.html)
1. Note the ARN of the new role as it is used below
1. Run the deploy the script ```
export FUNCTION_ROLE=XXXX; ./deploy.sh


## AWS Elasticsearch Service Access Policy

Depending on your setup you will need to add permissions for the lambda function role to
query/delete Elasticsearch indices. See AWS Elasticsearch documentation for more information.



### Thanks

Thanks to Cristian Uroz who wrote the original [gist](https://gist.github.com/cjuroz/d45f4d73e74f068892c5e4f3d1c7fa7c)
