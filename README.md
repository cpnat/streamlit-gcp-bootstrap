Bootstrap https://streamlit.io/ deployments on Google Cloud Platform

![Streamlit Logo](streamlit-logo-primary-colormark-darktext.png)

Build out your application within `app.py` and following the instructions below for local run, and deployment on Google Cloud Platform:

## Pre-requisites

0.1 - Install Docker Desktop (https://www.docker.com/products/docker-desktop) and Google Cloud SDK (https://cloud.google.com/sdk) on your machine

0.2 - Create a Service Acccount, with permissions to access your Bigquery project and download a JSON key file

0.3 - Create `./config/.env` containing variables to be used by your deployment. See `./config/.env.example` for a sample using dummy values.

| Environment variable           | Description                                                                                  |
|--------------------------------|----------------------------------------------------------------------------------------------|
| GOOGLE_CLOUD_PROJECT           | Your project                                                                                 |
| GOOGLE_CLOUD_ZONE              | Your zone                                                                                    |
| CLUSTER_NAME                   | The name you would like to assign to your cluster                                            |
| APP_NAME                       | The name you would like to assign to your app                                                |
| APP_VERSION                    | The version number of your app                                                               |
| BIGQUERY_TABLE                 | Test table, used to render some data in the sample app                                       |
| SERVICE_ACCOUNT_KEY            | Path to service account key, required for access to Bigquery                                 |
| DOMAIN_NAME                    | The domain name that you will point to the IP address associated with your Ingress           |

## Local run

1.1 - To run your application locally in a container:-

```
make run-container
```

## Initial Deployment

2.1 - Create a static IP record, a dependency for setting up HTTPS Ingress and Identity Aware Proxy. The A record must be added to your DNS before proceeding

```
make gcloud-static-ip
```

2.2 - Deploy your application, this encompasses the following stages:-
- Create a GKE cluster
- Register and associate an SSL certificate with your Ingress  
- Upload your service account key to the cluster (managed using K8S Secrets)  
- Build a container on Google Container Registry, and create the Deployment, Service and Ingress for your application 

```
make gcloud-deploy
```

2.3 - Setup Identity Aware Proxy https://cloud.google.com/iap/docs/enabling-kubernetes-howto (OAuth Consent, and Setting Up IAP access). Note, some default firewall rules may also need to be disabled.


## Re-deployment
Simply re-run the command below; un-necessary stages from the initial deployment will not be repeated.

```
make gcloud-deploy
```


## Clean
Sentinel files are used to keep track of stages that only need to be run once. If you wish to re-run a stage, you can remove the relevant file:-

```
gcloud-local-auth
gcloud-reserve-ip
gcloud-create-cluster
gcloud-ssl-certificate
gcloud-service
gcloud-ingress
gcloud-service-account-secret
```

## Merging this bootstrap code with an existing branch

In case you already have a repository with an existing application, you can merge the boostrap code using the following commands:-

-   Create a branch in your existing repository  

```
git checkout -b <my-branch>
```

- Add a secondary remote  

```
git remote add streamlit-gcp-bootstrap git@github.com:cpnat/streamlit-gcp-bootstrap.git
git remote update
```

 - Merge the master branch from the new remote  

```
git merge streamlit-gcp-boostrap/master
```
