
#export COMPARTMENT_NAME='experiment-container4' #give your compartment name if already created
export COMPUTE_NAME='TestCompute'
export COMPUTE_SHAPE='VM.Standard.E2.1.Micro'
export USER_HOME=$(eval echo ~)
echo "Host *" > ~/.ssh/config 
echo " StrictHostKeyChecking no" >> ~/.ssh/config
#uncomment and give parent container ID if new compartment not created already
#oci iam compartment create -c $1 --name "${COMPARTMENT_NAME}" --description "experiment using cli"
export COMPARTMENT_ID='ocid1.compartment.oc1..aaaaaaaaynm5wp77hfjamwwu5o55juhoktsg36pfdyfm3jgvvq5iwjbuh3gq'
export VCN_ID='ocid1.vcn.oc1.iad.amaaaaaair4bqaqaxk2ype2hbyh4emnnwizmunuqkbx6pwzaxiccokoffl7a'
export SUBNET_ID='ocid1.subnet.oc1.iad.aaaaaaaadqprunwiipbmlkij4ca2andirdgfjywea7hjtpthpomiajvixxxq'





export AVAILABILITY_DOMAIN=$(oci iam availability-domain list \
 --query "(data[?ends_with(name, '-3')] | [0].name) || data[0].name" \
 --raw-output)

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
export private_IP=$(oci compute instance list-vnics \
  --instance-id "${COMPUTE_OCID}" \
  --query 'data[0]."private-ip"' \
  --raw-output)
sleep 30
#echo "Host *" > ~/.ssh/config 
#echo " StrictHostKeyChecking no" >> ~/.ssh/config
until ssh opc@${COMPUTE_IP} 'ls'
do  
    echo "ssh running"
    sleep 10
done

ssh opc@${COMPUTE_IP} ' sudo yum install -y git ; sudo yum install -y docker ; sudo yum install -y docker-engine ; sudo service docker start ; sudo firewall-cmd --permanent --zone=public --add-service=http ; sudo firewall-cmd --reload ; sudo docker pull gaganvamsi/tc_oracle:latest ; sudo docker run -d -p8080:8080 gaganvamsi/tc_oracle:latest'

echo "setting up instances is done moving on to load-balancer ......."




export temp=$(pwd)
echo "[\"${SUBNET_ID}\"]" > ${temp}/subnets.json
echo "{\"minimumBandwidthInMbps\":10,\"maximumBandwidthInMbps\":10}" > ${temp}/shapedetails.json
export CREATED_LB=$(oci lb load-balancer create -c ${COMPARTMENT_ID} --display-name LB --shape-name flexible  --subnet-ids file://${temp}/subnets.json --shape-details file://${temp}/shapedetails.json)
rm ${temp}/subnets.json
rm ${temp}/shapedetails.json
export  WORK_REQUEST_ID=$(jq -r '."opc-work-request-id"' <<< "$CREATED_LB")
export WORK_REQUEST=$(oci lb work-request get --work-request-id $WORK_REQUEST_ID)

export WORK_REQUEST_STATUS=$(jq -r '.data."lifecycle-state"' <<< "$WORK_REQUEST")
    echo "created load-balancer status: $WORK_REQUEST_STATUS"
    while [[ $WORK_REQUEST_STATUS != "SUCCEEDED" ]]
    do  
        sleep 20
        WORK_REQUEST=$(oci lb work-request get --work-request-id $WORK_REQUEST_ID)
        WORK_REQUEST_STATUS=$(jq -r '.data."lifecycle-state"' <<< "$WORK_REQUEST")
        echo "created load-balancer status: $WORK_REQUEST_STATUS"
        
    done
export LB_ID=$(jq -r '.data."load-balancer-id"' <<< "$WORK_REQUEST")
    echo "Load Balancer OCID: $LB_ID"

export CREATED_BS=$(oci lb backend-set create --health-checker-protocol HTTP --load-balancer-id $LB_ID --name TC --policy ROUND_ROBIN --health-checker-url-path "/" --health-checker-port 8080   --health-checker-return-code 404 --wait-for-state SUCCEEDED)
    
export CREATED_B=$(oci lb backend create --load-balancer-id $LB_ID  --backend-set-name TC --ip-address ${private_IP}  --port 8080 --weight 3 --wait-for-state SUCCEEDED)

export CREATED_L=$(oci lb listener create  --default-backend-set-name TC --load-balancer-id $LB_ID --name TC_listener --port 8080 --protocol HTTP --wait-for-state SUCCEEDED)

export lb=$(oci lb load-balancer get --load-balancer-id $LB_ID)
export LB_IP=$(jq -r '.data."ip-addresses"[0]."ip-address"' <<< "$lb")
echo $LB_IP


# openssl rand -base64 32 for password for wallet
# docker cp <src-path> <container>:<dest-path> ... for wallet