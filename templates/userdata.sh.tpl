#!/bin/bash -xe

# get the instance lifecycle
iid=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
export AWS_DEFAULT_REGION=${AWS::Region}
ilc=$(aws ec2 describe-instances --instance-ids  "${iid}"  --query 'Reservations[0].Instances[0].InstanceLifecycle' --output text)

# Allow user supplied pre userdata code
${pre_userdata}

# Bootstrap and join the cluster
if [ "$ilc" == "spot" ]; then
    /etc/eks/bootstrap.sh --b64-cluster-ca '${cluster_auth_base64}' --apiserver-endpoint '${endpoint}' ${bootstrap_extra_args} --kubelet-extra-args '--node-labels=lifecycle=Ec2Spot --register-with-taints=spotInstance=true:PreferNoSchedule ${kubelet_extra_args}' '${cluster_name}'
else
    /etc/eks/bootstrap.sh --b64-cluster-ca '${cluster_auth_base64}' --apiserver-endpoint '${endpoint}' ${bootstrap_extra_args} --kubelet-extra-args '--node-labels=lifecycle=OnDemand ${kubelet_extra_args}' '${cluster_name}'
fi

# Allow user supplied userdata code
${additional_userdata}
