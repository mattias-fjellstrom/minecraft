# EC2 with cfn-init

Sets up the Minecraft server on an EC2 instance running Amazon Linux 2.

The difference between this example and the regular EC2 example is that this example uses `cfn-init`
and the `AWS::CloudFormation::Init` block to specify how the instance should be configured.

Note that the server is started as the root user.

## Instructions

### Deploy

Set up the Minecraft instance in the `eu-west-1` region (Ireland) with

```sh
./deploy.sh eu-west-1
```

Use a different region if you wish.

### Delete

Delete the infrastructure with

```sh
./delete.sh
```
