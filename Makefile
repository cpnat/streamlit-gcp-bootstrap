.DEFAULT_GOAL := help

help:
	@echo Make goals
	@echo - run
	@echo - run-container
	@echo - gloud-set-project
	@echo - gcloud-get-cluster-credentials
	@echo - gloud-create-cluster
	@echo - gcloud-server-ip
	@echo - gcloud-ssl-certificte
	@echo - gcloud-service-account-secret
	@echo - gcloud-deploy

run:
	@streamlit run app.py --server.port=8080 --server.address=0.0.0.0

run-container:
	@docker build . -t ${APP_NAME}
	@docker run -p 8080:8080 \
		-e BIGQUERY_TABLE=${BIGQUERY_TABLE} \
		-e GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT} \
		-e GOOGLE_APPLICATION_CREDENTIALS=/tmp/keys/adc.json \
		-v ${GOOGLE_APPLICATION_CREDENTIALS}:/tmp/keys/adc.json:ro \
		${APP_NAME}

gcloud-local-auth:
	@gcloud auth login

gcloud-set-project:
	@gcloud config set project ${GOOGLE_CLOUD_PROJECT}
	@gcloud config set compute/zone ${GOOGLE_CLOUD_ZONE}

gcloud-get-cluster-credentials:
	@gcloud container clusters get-credentials ${CLUSTER_NAME}

gcloud-create-cluster: gcloud-set-project
	@gcloud container clusters create ${CLUSTER_NAME} --num-nodes=1 --labels google-kubernetes-engine=streamlit

gcloud-reserve-ip: gcloud-set-project
	@gcloud compute addresses create ${APP_NAME} --global
	@gcloud compute addresses describe ${APP_NAME} --global

	@echo Create an A-Record in you DNS

gcloud-ssl-certificate: gcloud-set-project gcloud-get-cluster-credentials
	@cat certificate.yaml | envsubst '$${APP_NAME} $${DOMAIN_NAME}' | kubectl apply -f

gcloud-service-account-secret: gcloud-set-project gcloud-get-cluster-credentials
	@kubectl delete secret credentials || true
	@kubectl create secret generic credentials --from-file=credentials.json=${SERVICE_ACCOUNT_KEY}

gcloud-deploy: gcloud-set-project gcloud-get-cluster-credentials
	@docker build -t gcr.io/${GOOGLE_CLOUD_PROJECT}/${APP_NAME}:v${APP_VERSION} .
	@docker push gcr.io/${GOOGLE_CLOUD_PROJECT}/${APP_NAME}:v${APP_VERSION}

	@kubectl delete deployment ${APP_NAME}|| true
	@kubectl delete service ${APP_NAME} || true
	@kubectl delete ingress ${APP_NAME} || true

	@cat deployment.yaml | envsubst '$${APP_NAME} $${BIGQUERY_TABLE} $${GOOGLE_CLOUD_PROJECT} $${APP_VERSION}' | kubectl apply -f -
	@cat service.yaml | envsubst '$${APP_NAME}' | kubectl apply -f -

	@# just used for testing
	@if [ -z '$${DOMAIN_NAME}' ] ;\
		then cat ingress-test.yaml | envsubst '$${APP_NAME}' | kubectl apply -f - ;\
		else cat ingress.yaml| envsubst '$${APP_NAME}' | kubectl apply -f -; fi



