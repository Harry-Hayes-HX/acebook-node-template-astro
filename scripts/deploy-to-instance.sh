sudo apt-get update -y
sudo apt-get install -y openssh-client rsync

echo $INSTANCE_IP

eval $(ssh-agent -s)
echo "$ASTRONAUT_TOKEN" | tr -d '\r' | ssh-add -
mkdir -p ~/.ssh
chmod 700 ~/.ssh


# we should probably avoid hardcoding this, in case
# the IP changes
rsync -av -e "ssh -o StrictHostKeyChecking=no" ./* ec2-user@$INSTANCE_IP:/var/acebook/
ssh -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP "sudo systemctl restart acebook"
