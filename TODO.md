- [ ] How do I test IPV6?
- [ ] Make https://d3caezcsk6n3ww.cloudfront.net/subdirectory work so it serves
           https://d3caezcsk6n3ww.cloudfront.net/subdirectory/index.html
- [ ] Make 404 or similar work when S3 doesn't have an object, e.g.
        https://d3caezcsk6n3ww.cloudfront.net/what.txt

:arrow_up: I think for both of these, I might have to make the bucket and s3 website -> If i do, can I still make sure it isn't reachable by the bucket url? Similarily, can I make sure that https://d3caezcsk6n3ww.cloudfront.net isn't public?


## Ideas

### Site

- A CloudWatch dashboard for watching traffic to sites
- Cost calculator dashboard to show cost per site
- Basic WAF to each CF distribution for simple protection

### Lambda
