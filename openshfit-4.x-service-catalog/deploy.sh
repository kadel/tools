#!/bin/sh

# https://docs.openshift.com/container-platform/4.2/applications/service_brokers/installing-service-catalog.html

echo "* Enable the service catalog API server."
oc patch servicecatalogapiservers cluster --type='json' -p='[{"op": "replace", "path": "/spec/managementState", "value":"Managed"}]'
echo "* Enable the service catalog controller manager."
oc patch servicecatalogcontrollermanagers cluster --type='json' -p='[{"op": "replace", "path": "/spec/managementState", "value":"Managed"}]'

echo "* Install Template Service Broker"
tsb_namespace="openshift-template-service-broker"

echo "** Create $tsb_namespace namespace"
oc create namespace openshift-template-service-broker

echo "** Create OperatorHub subscription for Tempalte Service Broker"
oc -n $tsb_namespace create -f tsb-subscription.yaml

# wait for Template Service Broker operator
subscription_name="openshifttemplateservicebroker"
echo "*** Wating for subscription $subscription_name to be in AtLatestKnown state"
for i in $(seq 1 10); do
    echo "  $i. try"
    state="$(oc -n openshift-template-service-broker get subscriptions $subscription_name -o jsonpath="{.status.state}")"
    echo "  status.state = $state"
    if [ "$state" = "AtLatestKnown" ]; then
        break
    fi
    sleep 2
done

echo "** Create Template Service Broker instance"
oc -n $tsb_namespace create -f tsb-instance.yaml



