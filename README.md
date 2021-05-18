Bootstrap https://streamlit.io/ deployments on Google Cloud Platform

![Streamlit Logo](streamlit-logo-primary-colormark-darktext.png)

Build out your application within `app.py` and use the following Make goals for local run and deployment to Google Cloud Platform:-

| Make goal              | Description                                                                                                                                                                                         |
|------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| run                    | Runs your streamlit application locally; as a pre-requisite activate a virtualenv and `pip install -r requirements.txt`                                                                             |
| run-container          | Builds and runs a Docker container locally                                                                                                                                                          |
| gcloud-create-cluster  | Creates a Google Kubernetes Engine cluster, used to deploy your application. You can also use an existing cluster.                                                                                  |
| gcloud-static-ip       | Creates a static IP record, a dependency for setting up HTTPS Ingress and Identity Aware Proxy. The A record must be added to your DNS before executing `gloud-deploy` and `gcloud-ssl-certificate` |
| gcloud-ssl-certificate | Registers and associated an SSL certificate with your Ingress                                                                                                                                   |
| gcloud-deploy          | Builds a container on Google Container Registry, and creates the Deployment, Service and Ingress for your application                                                                               |

### Local run

`run` and `run-container`facilitate running your application locally

### Initial Deployment

1 - Create an Service Acccount, with permissions to access your Bigquery project and download a JSON key file

2 - Authenticate your local machine `make gcloud-local-auth`

3 - Register a static IP address `make gcloud-static-ip` and then add an A-Record to your DNS

4 - Setup environment variables; as below:-

| Environment variable           | Description                                                                                  |
|--------------------------------|----------------------------------------------------------------------------------------------|
| GOOGLE_CLOUD_PROJECT           | Your project                                                                                 |
| GOOGLE_CLOUD_ZONE              | Your zone                                                                                    |
| CLUSTER_NAME                   | The name you would like to assign to your cluster                                            |
| APP_NAME                       | The name you would like to assign to your app                                                |
| APP_VERSION                    | The version number of your app                                                               |
| BIGQUERY_TABLE                 | Test table, used to render some data in the sample app                                       |
| GOOGLE_APPLICATION_CREDENTIALS | Path to gcloud auth credentials file (created by `gcloud auth login`), used for local run    |
| SERVICE_ACCOUNT_KEY            | Path to service account key, required for access to Bigquery                                 |
| DOMAIN_NAME                    | The domain name that you will point to the IP address associated with your Ingress           |

5 - Create a Kubernetes cluster if required using `make gcloud-create-cluster`

6 - Register an SSL certificate `make gcloud-ssl-certificate`

7 - Upload your service account key to the cluster (managed using K8S Secrets) `make gcloud-service-account-secret`

8 - Deploy the application to your cluster `make gcloud-deploy`

9 - Setup Identity Aware Proxy https://cloud.google.com/iap/docs/enabling-kubernetes-howto (OAuth Consent, and Setting Up IAP access)

### Subsequent deployment

After initial setup, to re-reploy new versions of your application, simply run `make gcloud-deploy`
