Bootstrap https://streamlit.io/ deployments on Google Cloud Platform

![Streamlit Logo](streamlit-logo-primary-colormark-darktext.png)

Build out your application within `app.py` and use the following Make goals for local run and deployment to Google Cloud Platform:-

| Make goal              | Description                                                                                                                                                                                         |
|------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| run                    | Runs your streamlit application locally; as a pre-requisite activate a virtualenv and `pip install -r requirements.txt`                                                                             |
| run-container          | Builds and runs a Docker container locally                                                                                                                                                          |
| gcloud-create-cluster  | Creates a Google Kubernetes Engine cluster, used to deploy your application. You can also use an existing cluster.                                                                                  |
| gcloud-static-ip       | Creates a static IP record, a dependency for setting up HTTPS Ingress and Identity Aware Proxy. The A record must be added to your DNS before executing `gloud-deploy` and `gcloud-ssl-certificate` |
| gcloud-deploy          | Builds a container on Google Container Registry, and creates the Deployment, Service and Ingress for your application                                                                               |
| gcloud-ssl-certificate | Registers and associated an SSL certificate with your application                                                                                                                                   |

`gcloud-static-ip` and `google-ssl-certificate` are optional, and only required if you would like to setup HTTPS and enable Identity Aware Proxy for your application. If you wish to do so, use the following guide for enabling Identity Aware Proxy to complete the setup:- https://cloud.google.com/iap/docs/enabling-kubernetes-howto (OAuth Consent, and Setting Up IAP access) 

Note, the Make goals in this template reference environment variables - which need to be set as follows:-

| Environment variable           | Description                                                                                  |
|--------------------------------|----------------------------------------------------------------------------------------------|
| GOOGLE_CLOUD_PROJECT           | Your project                                                                                 |
| GOOGLE_CLOUD_ZONE              | Your zone                                                                                    |
| CLUSTER_NAME                   | The name you would like to assign to your cluster                                            |
| APP_NAME                       | The name you would like to assign to your app                                                |
| APP_VERSION                    | The version number of your app                                                               |
| BIGQUERY_TABLE                 | Test table, used to render some data in the sample app                                       |
| GOOGLE_APPLICATION_CREDENTIALS | Path to gcloud auth credentials file (created by `gcloud auth login`), used for local run    |
| DOMAIN_NAME                    | OPTIONAL; the domain name that you will point to the IP address associated with your Ingress |

