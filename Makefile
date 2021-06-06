include ./config/.env
export

.DEFAULT_GOAL := help

help:
	@echo Make goals
	@echo - run
	@echo - run-container
	@echo - gcloud-local-auth
	@echo - gloud-set-project
	@echo - gcloud-get-cluster-credentials
	@echo - gcloud-create-cluster
	@echo - gcloud-reserve-ip
	@echo - gcloud-ssl-certificte
	@echo - gcloud-service-account-secret
	@echo - gcloud-deploy

clean:
	rm -f -- gcloud-local-auth \
	gcloud-get-cluster-credentials \
	gcloud-create-cluster \
	gcloud-reserve-ip \
	gcloud-ssl-certificate \
	gcloud-reserve-ip

run:
	@streamlit run app/app.py --server.port=8080 --server.address=0.0.0.0

run-container:
	@docker build . -t ${APP_NAME}
	@docker run -p 8080:8080 \
		-e BIGQUERY_TABLE=${BIGQUERY_TABLE} \
		-e GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT} \
		-e GOOGLE_APPLICATION_CREDENTIALS=/tmp/keys/adc.json \
		-v ${SERVICE_ACCOUNT_KEY}:/tmp/keys/adc.json:ro \
		${APP_NAME}

gcloud-local-auth:
	@mkdir -p $(@D)
	@gcloud auth login
	@touch $@

gcloud-set-project: gcloud-local-auth
	@gcloud config set project ${GOOGLE_CLOUD_PROJECT}
	@gcloud config set compute/zone ${GOOGLE_CLOUD_ZONE}

gcloud-get-cluster-credentials: gcloud-set-project
	@gcloud container clusters get-credentials ${CLUSTER_NAME}

gcloud-create-cluster: gcloud-set-project
	@mkdir -p $(@D)
	@gcloud container clusters create ${CLUSTER_NAME} --num-nodes=1 --max-nodes=10  --enable-autoscaling --labels google-kubernetes-engine=streamlit
	@touch $@

gcloud-reserve-ip: gcloud-set-project
	@mkdir -p $(@D)
	@gcloud compute addresses delete ${APP_NAME}|| true
	@gcloud compute addresses create ${APP_NAME} --global
	@gcloud compute addresses describe ${APP_NAME} --global
	@echo Create an A-Record in you DNS
	@touch $@

gcloud-ssl-certificate: gcloud-get-cluster-credentials
	@mkdir -p $(@D)
	@kubectl delete certificate ${APP_NAME}|| true
	@cat /config/certificate.yaml | envsubst '$${APP_NAME} $${DOMAIN_NAME}' | kubectl apply -f -
	@touch $@

gcloud-service-account-secret: gcloud-get-cluster-credentials
	@mkdir -p $(@D)
	@kubectl delete secret credentials || true
	@kubectl create secret generic credentials --from-file=credentials.json=${SERVICE_ACCOUNT_KEY}
	@touch $@

gcloud-deploy: gcloud-get-cluster-credentials gcloud-ssl-certificate gcloud-service-account-secret
	@docker build -t gcr.io/${GOOGLE_CLOUD_PROJECT}/${APP_NAME}:v${APP_VERSION} .
	@docker push gcr.io/${GOOGLE_CLOUD_PROJECT}/${APP_NAME}:v${APP_VERSION}

	@kubectl delete deployment ${APP_NAME}|| true
	@kubectl delete service ${APP_NAME} || true
	@kubectl delete ingress ${APP_NAME} || true
	@cat /config/deployment.yaml | envsubst '$${APP_NAME} $${BIGQUERY_TABLE} $${GOOGLE_CLOUD_PROJECT} $${APP_VERSION}' | kubectl apply -f -
	@cat /config/service.yaml | envsubst '$${APP_NAME}' | kubectl apply -f -
	@cat /config/ingress.yaml | envsubst '$${APP_NAME}' | kubectl apply -f -
