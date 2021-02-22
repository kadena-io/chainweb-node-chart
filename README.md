**Disclaimer:** So far, this chart has only been tested on Google Kubernetes
Engine (GKE). Adjustments may be needed to run it on other Kubernetes
deployments. Any feedback regarding experience with other environments is
welcome.

# Chainweb Node Chart

An application that runs Chainweb nodes in the backend and optionally includes
ingresses for the following Chainweb API endpoints:

Chainweb Service API endpoints:

*   `/info`
*   `/health-check`
*   `/chainweb/0.0/mainnet01/chain/[0-9]+/pact/.*`
*   `/chainweb/0.0/mainnet01/rosetta/.*`
*   `/chainweb/0.0/mainnet01/header/updates`
*   `/chainweb/0.0/mainnet01/mining`

Chainweb P2P API endpoints:

*   `/chainweb/0.0/mainnet01/chain/[0-9]+/(header|hash|branch|payload).*`
*   `/chainweb/0.0/mainnet01/cut`

There is a number of configuration options that can be adjusted through
adjusting or overriding the settings in `values.yaml`. Please, read the comments
in that file and also carefully read the instructions below in this file.

## Cluster Requirements

Kubernets nodes that run Chainweb node pods must have an external IP address and
the P2P port of the nodes must be publicly available directly without transport
level or higher level load balancers or proxies.

Nodes have affinity rules that guarantee that only a single Chainweb node can on
any Kuberentes node. Therefore the replicaCount of Chainweb nodes must be
smaller than or equal to the number of available Kubernetes nodes in the
cluster.

Nodes maintain their own database on a persistent volume. This Chart has been
tested on GKE and you may have to adjust the storage class configurations to
match the storage backend provides of your cluster.

## DNS and Static IP Address

When enabling an ingress with TLS the load balancer needs a static, permanent IP
address and a domain name that points to that IP.

Please consult the documentation of your Kubernetes cluster about how to obtain
a static IP address.

If you use GKE you can first create the service (with ingress enabled and TLS
*disabled*) and then lookup the ephemeral IP address that is assigned to the load
balancer via:

```sh
kubectl get service
```

After that the ephemeral IP address can be promoted to a permanent IP address
via the command

```
gcloud compute addresses create ipv4-DOMAIN --addresses TODO_YOUR_IP_ADDRESS
```

This IP address is then used to setup the DNS record for the cluster. After that
TLS is enabled and the IP address is passed to the application values as

```yaml
ingress-nginx:
  controller:
    service:
      loadBalancerIP: TODO_YOUR_IP_ADDRESS
```

(or the respective `--set` option on the helm command line).

## TLS Certificates

This chart includes an option to install cert-manager as a dependency. However,
this does not seem to work reliably. It is recommended to install cert-manager
manually before installing this Chart. The default settings should be work fine.

```sh
kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v1.2.0 \
    --set installCRDs=true
```

## Image Pull Secrets

If using a private image, an image pull secrete must be configured and deployed
to the Kubernetes cluster.

```sh
kubectl create secret docker-registry SECRET_NAME \
    --docker-server=<your-registry-server> \
    --docker-username=<your-name> \
    --docker-password=<your-pword> \
    --docker-email=<your-email>
```

After that the name of the secret is added to the `values.yaml` file:

```yaml
imagePullSecrets:
- name: SECRET_NAME
```


Please, consult the documentation of your image registry about further details
on how to create Kubernetes secrets for authentication.

## Configuring Ingress

There are a number ingresses defined for different sub-APIs. When the global
`ingress.enabled` flag is set to true, one *must* provide a value for
`ingress.host`, which is used as the default `host` value of an ingress that
does not define its own `host` value.

The ingresses can be configured through global annotations and configuration
settings. Also, each ingress can be configured individually via annotations.

Some APIs also require that the respective features is enabled in the Chainweb
node applications itself, which can be done in the `features` section of the
values file.

## Database initialization

Each Chainweb node pod has its own database persistent volume. Initializing the
database can take a long time. If no database snapshot URL is provided the node
will catchup with the network by replaying the complete mainnet database while
rebuilding the database. This can take several days.

Alternatively, an URL can be provided that point to a tar.gz archive of a
database snapshot, which is queried via curl and used to initialize the data on
the db volume.

Kadena publishes recent snapshots at
https://kadena-node-db.s3.us-east-2.amazonaws.com/db-chainweb-node-ubuntu.18.04-latest.tar.gz
This URL can't be used directly, but must be signed for S3 requester-pay
requests.

**IMPORT: Only use database snapshots from a trusted source!**

