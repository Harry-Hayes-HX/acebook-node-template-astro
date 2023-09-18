apt-get update -y
apt-get install -y openssh-client rsync

eval $(ssh-agent -s)
echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# The instance ip address is 52.12.34.133
# we should probably avoid hardcoding this, in case
# the IP changes
rsync -av -e "ssh -o StrictHostKeyChecking=no" ./* ec2-user@52.12.34.133:/var/acebook/
ssh -o StrictHostKeyChecking=no ec2-user@52.12.34.133 "sudo systemctl restart acebook"
