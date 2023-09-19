# This script does the following:
#  * Start a new temporary instance from the Acebook base image
#  * Copy the new codebase into the instance
#  * Creates a new image
#  * Terminate the instance

if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
    echo "You must provide AWS_ACCESS_KEY_ID in environment variables" 1>&2
    exit 1
fi

if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo "You must provide AWS_SECRET_ACCESS_KEY in environment variables" 1>&2
    exit 1
fi

# 0 - Configure AWS CLI
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=eu-west-2

# 1 - Create a temporary keypair
yes | ssh-keygen -t rsa -f keypair -q -N ""
echo " -> created keypair"

# 2 - Start a new instance for the build
export INSTANCE_ID=$(aws ec2 run-instances --image-id "ami-0da7f840f6c348e2d" --instance-type "t2.micro" --query 'Instances[0].InstanceId' --output text)
echo " -> started build instance $INSTANCE_ID"

echo $INSTANCE_ID > ./build_instance_id
export INSTANCE_DESCRIPTION=`aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID`
# Pull out our important variables
export INSTANCE_AZ=`echo $INSTANCE_DESCRIPTION | jq -r .Reservations[0].Instances[0].Placement.AvailabilityZone`
export INSTANCE_IP=`echo $INSTANCE_DESCRIPTION | jq -r .Reservations[0].Instances[0].PublicIpAddress`

# 3 - Connect to SSH
echo " -> waiting"  
sleep 30
echo " -> trying to SSH"
aws ec2-instance-connect send-ssh-public-key \
  --instance-id $INSTANCE_ID \
  --instance-os-user ec2-user \
  --availability-zone $INSTANCE_AZ \
  --ssh-public-key file://./keypair.pub
echo " -> waiting"  
sleep 10
ssh  -o StrictHostKeyChecking=accept-new \
    -i ./keypair ec2-user@$INSTANCE_IP \
    "sudo chown ec2-user /var/acebook"
rsync -av -e "ssh -o StrictHostKeyChecking=no" ./* ec2-user@$INSTANCE_IP:/var/acebook/

echo " -> copying files"  
scp -o StrictHostKeyChecking=accept-new \
    -i ./keypair \
    -r ./build_instance_id ec2-user@$INSTANCE_IP:/var/acebook

ssh  -o StrictHostKeyChecking=accept-new \
    -i ./keypair ec2-user@$INSTANCE_IP \
    "ls -la /var/acebook"

# Creating AMI from instance
export AMI_VERSION=$(date +'%d-%m-%Y-%H-%M')
aws ec2 create-image \
    --instance-id $INSTANCE_ID \
    --name "acebook-build-$AMI_VERSION" \
    --no-reboot

# Cleanup
echo " -> terminating instance"
aws ec2 terminate-instances --instance-ids $INSTANCE_ID > /dev/null
rm -f keypair keypair.pub build_instance_id

echo "-> done"