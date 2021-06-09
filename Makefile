include ./config/.env
export

.DEFAULT_GOAL := help

help:
	@echo Make goals
	@echo - run-container
	@echo - gcloud-local-auth
	@echo - gloud-set-project
	@echo - gcloud-reserve-ip
	@echo - gcloud-create-cluster
	@echo - gcloud-get-cluster-credentials
	@echo - gcloud-ssl-certificte
	@echo - gcloud-service-account-secret
	@echo - gcloud-service
	@echo - gcloud-ingress
	@echo - gcloud-deploy

run-container:
	@docker build . -t ${APP_NAME}
	@docker run -p 8080:8080 \
		-e GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT} \
		-e GOOGLE_APPLICATION_CREDENTIALS=/tmp/keys/adc.json \
		-v ${SERVICE_ACCOUNT_KEY}:/tmp/keys/adc.json:ro \
		${APP_NAME}

gcloud-local-auth:
	@gcloud auth login
	@touch $@

gcloud-set-project: gcloud-local-auth
	@gcloud config set project ${GOOGLE_CLOUD_PROJECT}
	@gcloud config set compute/zone ${GOOGLE_CLOUD_ZONE}

gcloud-reserve-ip: gcloud-set-project
	@if [ !  -f '$@' ]; then \
  		gcloud compute addresses delete ${CLUSTER_NAME} || true; \
  		gcloud compute addresses create ${APP_NAME} --global; \
		gcloud compute addresses describe ${APP_NAME} --global; \
		echo Create an A-Record in you DNS; \
		touch $@; \
	else echo '`$@` is up to date'; \
	fi

gcloud-create-cluster: gcloud-set-project
	@if [ !  -f '$@' ]; then \
  		gcloud container clusters delete ${CLUSTER_NAME} || true; \
		gcloud container clusters create ${CLUSTER_NAME} --num-nodes=1 --max-nodes=10  --enable-autoscaling --labels google-kubernetes-engine=streamlit; \
		touch $@; \
	else echo '`$@` is up to date'; \
	fi

gcloud-get-cluster-credentials: gcloud-set-project
	@gcloud container clusters get-credentials ${CLUSTER_NAME}

gcloud-ssl-certificate: gcloud-get-cluster-credentials
	@if [ !  -f '$@' ]; then \
		kubectl delete certificate ${APP_NAME}|| true; \
		cat ./config/certificate.yaml | envsubst '$${APP_NAME} $${DOMAIN_NAME}' | kubectl apply -f -; \
		touch $@; \
	else echo '`$@` is up to date'; \
	fi

gcloud-service-account-secret: gcloud-get-cluster-credentials
	@if [ !  -f '$@' ]; then \
		kubectl delete secret credentials || true; \
		kubectl create secret generic credentials --from-file=credentials.json=${SERVICE_ACCOUNT_KEY}; \
		touch $@; \
	else echo '`$@` is up to date'; \
	fi

gcloud-service: gcloud-get-cluster-credentials
	@if [ !  -f '$@' ]; then \
		kubectl delete service ${APP_NAME} || true; \
		cat ./config/service.yaml | envsubst '$${APP_NAME}' | kubectl apply -f -; \
		touch $@; \
	else echo '`$@` is up to date'; \
	fi

gcloud-ingress: gcloud-get-cluster-credentials
	@if [ !  -f '$@' ]; then \
		kubectl delete ingress ${APP_NAME} || true; \
		cat ./config/ingress.yaml | envsubst '$${APP_NAME}' | kubectl apply -f -; \
		touch $@; \
	else echo '`$@` is up to date'; \
	fi

gcloud-deploy: gcloud-create-cluster gcloud-get-cluster-credentials \
	gcloud-ssl-certificate gcloud-service-account-secret gcloud-service gcloud-ingress

	@kubectl delete deployment ${APP_NAME}|| true
	@cat ./config/deployment.yaml | envsubst '$${APP_NAME} $${GOOGLE_CLOUD_PROJECT} $${APP_VERSION}' | kubectl apply -f -
