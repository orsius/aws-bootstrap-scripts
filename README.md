# aws-bootstrap-scripts
<<<<<<<
Use these basics aws-bootstrap-scripts in order to Install the configuration of your choice on a RHEL7 linux server.

## Requirements

* have an AWS account [AWS account](https://aws.amazon.com/)
* work with the AWS EC2 rhel7 image [AWS AMIs](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
* EC2 instance should be able to access the Internet to retreived packages.

## Technology included

* [RHEL7](https://access.redhat.com/downloads)
* [Elasticsearch](https://www.elastic.co/products/elasticsearch)
* [Kibana](http://elastic.co/)

## Running

Clone the repository.
login on AWS, select EC3
launch instance, select Red Hat "Enterprise Linux 7.3" with a type "t2.medium"
On the "configure instance detail page" Adapt the host names and fils the values accordingly to your needs then clic on "Advanced Details" > user data > as input file and pickup the corresponding shell script.

Run the instance.

```sh
$ ssh -i key.pey ec2user@${yourAWSserver}
```

## Official aws docs

more information can be found under the [AWS getting started webpage](https://aws.amazon.com/ec2/getting-started/)
