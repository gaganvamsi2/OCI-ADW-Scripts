
export COMPARTMENT_NAME='experiment-container4' #give your compartment name if already created
export COMPUTE_NAME1='TestCompute1'
export COMPUTE_NAME2='TestCompute2'
export COMPUTE_NAME3='TestCompute3'
export COMPUTE_SHAPE1='VM.Standard.E2.1.Micro'
export COMPUTE_SHAPE2='VM.Standard.E2.1.Micro'
export COMPUTE_SHAPE3='VM.Standard.E2.1.Micro'
export USER_HOME=$(eval echo ~)

#uncomment and give parent container ID if new compartment not created already
#oci iam compartment create -c $1 --name "${COMPARTMENT_NAME}" --description "experiment using cli"
export COMPARTMENT_ID=$(oci iam compartment list \
--query "data[?name=='${COMPARTMENT_NAME}'].id |[0] " \
 --raw-output)



export AVAILABILITY_DOMAIN1=$(oci iam availability-domain list \
 --query "(data[?ends_with(name, '-3')] | [0].name) || data[0].name" \
 --raw-output)

export AVAILABILITY_DOMAIN2=$(oci iam availability-domain list \
 --query "(data[?ends_with(name, '-3')] | [0].name) || data[0].name" \
 --raw-output)

 export AVAILABILITY_DOMAIN3=$(oci iam availability-domain list \
 --query "(data[?ends_with(name, '-3')] | [0].name) || data[0].name" \
 --raw-output)

export VCN_ID=$(oci network vcn create \
 -c ${COMPARTMENT_ID} --cidr-block "10.0.0.0/16" \
 --display-name "VCN-CLI" \
 --dns-label "VCN" \
 --query "data.id"  \
 --raw-output)


export SUBNET_ID1=$(oci network subnet create \
 --vcn-id ${VCN_ID} \
 -c ${COMPARTMENT_ID} \
 --availability-domain "OvJZ:US-ASHBURN-AD-3" \
 --display-name "subnet-1" \
 --cidr-block "10.0.2.0/24" \
 --query "data.id" \
 --raw-output)

 export SUBNET_ID2=$(oci network subnet create \
 --vcn-id ${VCN_ID} \
 -c ${COMPARTMENT_ID} \
 --availability-domain "OvJZ:US-ASHBURN-AD-3" \
  --display-name "subnet-2" \
 --cidr-block "10.0.3.0/24" \
 --query "data.id" \
 --raw-output)

export SUBNET_ID3=$(oci network subnet create \
 --vcn-id ${VCN_ID} \
 -c ${COMPARTMENT_ID} \
 --availability-domain "OvJZ:US-ASHBURN-AD-3" \
  --display-name "subnet-3" \
 --cidr-block "10.0.4.0/24" \
 --query "data.id" \
 --raw-output)



export IG_ID=$(oci network internet-gateway create \
 -c ${COMPARTMENT_ID} \
 --is-enabled true \
 --vcn-id ${VCN_ID} \
 --query "data.id" \
 --raw-output)



export RT_ID=$(oci network route-table list \
-c ${COMPARTMENT_ID} \
--vcn-id ${VCN_ID} \
--query "data[0].id" \
--raw-output)


oci network route-table update --rt-id ${RT_ID} --route-rules '[{"cidrBlock":"0.0.0.0/0","networkEntityId":"'${IG_ID}'"}]' --force




export SL_ID=$(oci network security-list list \
-c ${COMPARTMENT_ID} \
--vcn-id ${VCN_ID} \
--query "data[0].id" \
--raw-output)
oci network security-list update --security-list-id ${SL_ID}  --ingress-security-rules '[{"source": "0.0.0.0/0", "protocol": "6", "tcpOptions": {"destinationPortRange": {"max": 80, "min": 80}}}]' --force
oci network security-list update --security-list-id ${SL_ID}  --ingress-security-rules '[{"source": "0.0.0.0/0", "protocol": "6", "tcpOptions": {"destinationPortRange": {"max": 8080, "min": 8080}}}]' --force



export COMPUTE_OCID1=$(oci compute instance launch \
 -c ${COMPARTMENT_ID} \
 --shape "${COMPUTE_SHAPE1}" \
 --display-name "${COMPUTE_NAME1}" \
 --image-id ocid1.image.oc1.iad.aaaaaaaamoajldhwrmbzx7s4xnrajj5b7nfrnutuebgwne4bxc7vpiap3gga \
 --ssh-authorized-keys-file "${USER_HOME}/.ssh/id_rsa.pub" \
 --subnet-id ${SUBNET_ID1} \
 --availability-domain "${AVAILABILITY_DOMAIN1}" \
 --wait-for-state RUNNING \
 --query "data.id" \
 --raw-output)
 
export COMPUTE_IP1=$(oci compute instance list-vnics \
  --instance-id "${COMPUTE_OCID1}" \
  --query 'data[0]."public-ip"' \
  --raw-output)

echo $COMPUTE_IP1

#ssh opc@${COMPUTE_IP1} 'sudo yum -y update ; sudo yum -y update;sudo yum install -y docker; sudo docker pull gaganvamsi/tc_oracle:latest; sudo docker run -p8080:8080 gaganvamsi/tc_oracle:latest'




export COMPUTE_OCID2=$(oci compute instance launch \
 -c ${COMPARTMENT_ID} \
 --shape "${COMPUTE_SHAPE2}" \
 --display-name "${COMPUTE_NAME2}" \
 --image-id ocid1.image.oc1.iad.aaaaaaaamoajldhwrmbzx7s4xnrajj5b7nfrnutuebgwne4bxc7vpiap3gga \
 --ssh-authorized-keys-file "${USER_HOME}/.ssh/id_rsa.pub" \
 --subnet-id ${SUBNET_ID2} \
 --availability-domain "${AVAILABILITY_DOMAIN2}" \
 --wait-for-state RUNNING \
 --query "data.id" \
 --raw-output)
 
export COMPUTE_IP2=$(oci compute instance list-vnics \
  --instance-id "${COMPUTE_OCID2}" \
  --query 'data[0]."public-ip"' \
  --raw-output)

echo $COMPUTE_IP2

#ssh opc@${COMPUTE_IP2} 'sudo yum -y update ; sudo yum -y update;sudo yum install -y docker; sudo docker pull gaganvamsi/tc_oracle:latest; sudo docker run -p8080:8080 gaganvamsi/tc_oracle:latest'




export COMPUTE_OCID3=$(oci compute instance launch \
 -c ${COMPARTMENT_ID} \
 --shape "${COMPUTE_SHAPE3}" \
 --display-name "${COMPUTE_NAME3}" \
 --image-id ocid1.image.oc1.iad.aaaaaaaahjkmmew2pjrcpylaf6zdddtom6xjnazwptervti35keqd4fdylca \
 --ssh-authorized-keys-file "${USER_HOME}/.ssh/id_rsa.pub" \
 --subnet-id ${SUBNET_ID3} \
 --availability-domain "${AVAILABILITY_DOMAIN3}" \
 --wait-for-state RUNNING \
 --query "data.id" \
 --raw-output)
 
export COMPUTE_IP3=$(oci compute instance list-vnics \
  --instance-id "${COMPUTE_OCID3}" \
  --query 'data[0]."public-ip"' \
  --raw-output) 

echo $COMPUTE_IP3
#echo "Host *" > ~/.ssh/config 
#echo " StrictHostKeyChecking no" >> ~/.ssh/config

#ssh opc@${COMPUTE_IP3} 'sudo yum -y update ;  sudo firewall-cmd --permanent --zone=public --add-service=http ; sudo firewall-cmd --reload; sudo yum -y update;sudo yum install -y docker;sudo service docker start; sudo docker pull gaganvamsi/tc_oracle:latest; sudo docker run -p8080:8080 gaganvamsi/tc_oracle:latest'