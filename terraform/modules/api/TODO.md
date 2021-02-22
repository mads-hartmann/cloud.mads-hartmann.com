# TODO

## MVP

- [x] Create the API Gateway resource
- [x] Lambda function
  - [x] Create an example hello-world in examples/api
  - [x] Define the Lambda resource
  - [x] Give the API Gateway permission to execute the lambda
  - [ ] Write a deploy script for the lambda function (decouple provisioning from releases)
- [ ] Terrform fails with "error creating Lambda Function: InvalidParameterValueException: Error occurred while GetObject. S3 Error Code: NoSuchKey. S3 Error Message" which is fair as the key indeed doesn't exist Initially. Some options:
  - [ ] Make the bucket an input variable; that way there's not race, the caller just has to make sure the bucket exists
  - [ ] Or, upload a dummy function as part of the provisioning?

## Later

- [ ] What would it take to add authentication?
- [ ] Enable CloudWatch logging
- [ ] Enable Honeycomb traces or x-ray
