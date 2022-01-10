# lambdash-efs

This is a fork of [lambdash by Eric Hammond](https://alestic.com/2015/06/aws-lambda-shell-2/), an AWS Lambda function that simply runs a shell command inside the Lambda runtime and returns its standard output & error; accompanied by a local command-line invocation helper.

We've modernized it to deploy using [Terraform](https://www.terraform.io/), and to make the [Lambda function mount an existing EFS file system](https://docs.aws.amazon.com/lambda/latest/dg/services-efs.html) at `/mnt/efs`. This provides a *serverless* facility to browse & manage EFS contents, at negligible cost whenever needed; filling a gap that exists while AWS Console lacks a browser for EFS contents, CloudShell can't mount EFS, etc.

### How to

Requirements:

* Local terminal with administrator credentials for your AWS account
* git, terraform, python3, boto3
* Existing EFS file system, and specifically:
  * EFS Access Point (`fsap-xxxx`)
  * VPC subnet (`subnet-xxxx`) that can reach the EFS
  * Security Group (`sg-xxxx`) that can reach the EFS

Deployment:

```bash
git clone https://github.com/miniwdl-ext/lambdash-efs.git
cd lambdash-efs
terraform init
terraform apply -var=aws_region=us-west-2 -var=fsap=fsap-xxxx -var=subnet=subnet-xxxx -var=sg=sg-xxxx
```

Example session:

```
$ ./lambdash uname -a
Linux 169.254.195.245 4.14.252-207.481.amzn2.x86_64 #1 SMP Wed Oct 27 20:57:19 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
$ ./lambdash bash -c 'echo Hello, world! > /mnt/efs/hello.txt'
$ ./lambdash ls /mnt/efs
hello.txt
$ ./lambdash cat /mnt/efs/hello.txt
Hello, world!
$ ./lambdash rm /mnt/efs/hello.txt
```

And naturally you may copy the `lambdash` script somewhere in your PATH.

### Limits

The Lambda function is configured with 256 MiB memory and 60-second timeout. The command's stdout & stderr are truncated at 64 MiB each.

### Alternatives

* [Simple File Manager for Amazon EFS](https://aws.amazon.com/solutions/implementations/simple-file-manager-for-amazon-efs/) serverless web app (not really so simple...)
* [SageMaker Studio](https://aws.amazon.com/sagemaker/studio/) managed JupyterHub accessed via AWS Console, attaching a built-in EFS (can't bring your own EFS)
* [Cloud Commander](https://cloudcmd.io/) web app to deploy on EC2 or Fargate, mounting your EFS (similarly [JupyterHub](https://jupyter.org/hub), [code-server](https://github.com/coder/code-server))
* SSH into an EC2 or Fargate server mounting your EFS
