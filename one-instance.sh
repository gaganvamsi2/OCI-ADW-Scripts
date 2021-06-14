
export COMPARTMENT_NAME='experiment-container4' #give your compartment name if already created
export COMPUTE_NAME='TestCompute'
export COMPUTE_SHAPE='VM.Standard.E2.1.Micro'
export USER_HOME=$(eval echo ~)

#uncomment and give parent container ID if new compartment not created already
#oci iam compartment create -c $1 --name "${COMPARTMENT_NAME}" --description "experiment using cli"
export COMPARTMENT_ID=$(oci iam compartment list \
--query "data[?name=='${COMPARTMENT_NAME}'].id |[0] " \
 --raw-output)



export AVAILABILITY_DOMAIN=$(oci iam availability-domain list \
 --query "(data[?ends_with(name, '-3')] | [0].name) || data[0].name" \
 --raw-output)


export VCN_ID=$(oci network vcn create \
 -c ${COMPARTMENT_ID} --cidr-block "10.0.0.0/16" \
 --display-name "VCN-CLI" \
 --dns-label "VCN" \
 --query "data.id"  \
 --raw-output)


export SUBNET_ID=$(oci network subnet create \
 --vcn-id ${VCN_ID} \
 -c ${COMPARTMENT_ID} \
 --cidr-block "10.0.2.0/24" \
 --query "data.id" \
 --raw-output)



export IG_ID=$(oci network internet-gateway create \
 -c ${COMPARTMENT_ID} \
 --is-enabled true \
 --vcn-id ${VCN_ID} \
 --query "data.id" \
 --raw-output)



export RT_ID=$(oci network route-table list -c ${COMPARTMENT_ID} --vcn-id ${VCN_ID} --query "data[0].id" --raw-output)

oci network route-table update --rt-id ${RT_ID} --route-rules '[{"cidrBlock":"0.0.0.0/0","networkEntityId":"'${IG_ID}'"}]' --force

export COMPUTE_OCID=$(oci compute instance launch \
 -c ${COMPARTMENT_ID} \
 --shape "${COMPUTE_SHAPE}" \
 --display-name "${COMPUTE_NAME}" \
 --image-id ocid1.image.oc1.iad.aaaaaaaahjkmmew2pjrcpylaf6zdddtom6xjnazwptervti35keqd4fdylca \
 --ssh-authorized-keys-file "${USER_HOME}/.ssh/id_rsa.pub" \
 --subnet-id ${SUBNET_ID} \
 --availability-domain "${AVAILABILITY_DOMAIN}" \
 --wait-for-state RUNNING \
 --query "data.id" \
 --raw-output)
 
export COMPUTE_IP=$(oci compute instance list-vnics \
  --instance-id "${COMPUTE_OCID}" \
  --query 'data[0]."public-ip"' \
  --raw-output)

echo $COMPUTE_IP
#echo "Host *" > ~/.ssh/config 
#echo " StrictHostKeyChecking no" >> ~/.ssh/config
until ssh -v opc@${COMPUTE_IP} ' ls'
do
    sleep 10
done

