#!/bin/bash
export temp=$(pwd)
echo "[\"ocid1.subnet.oc1.iad.aaaaaaaadqprunwiipbmlkij4ca2andirdgfjywea7hjtpthpomiajvixxxq\"]" > ${temp}/subnets.json
echo "{\"minimumBandwidthInMbps\":10,\"maximumBandwidthInMbps\":10}" > ${temp}/shapedetails.json
export CREATED_LB=$(oci lb load-balancer create -c ocid1.compartment.oc1..aaaaaaaaynm5wp77hfjamwwu5o55juhoktsg36pfdyfm3jgvvq5iwjbuh3gq --display-name LB --shape-name flexible  --subnet-ids file://${temp}/subnets.json --shape-details file://${temp}/shapedetails.json)
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
    
export CREATED_B=$(oci lb backend create --load-balancer-id $LB_ID  --backend-set-name TC --ip-address 192.168.3.6  --port 8080 --weight 3 --wait-for-state SUCCEEDED)

export CREATED_L=$(oci lb listener create  --default-backend-set-name TC --load-balancer-id $LB_ID --name TC_listener --port 80 --protocol HTTP --wait-for-state SUCCEEDED)

export lb=$(oci lb load-balancer get --load-balancer-id $LB_ID)
export LB_IP=$(jq -r '.data."ip-addresses"[0]."ip-address"' <<< "$lb")
echo $LB_IP
















