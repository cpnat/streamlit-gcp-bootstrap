.DEFAULT_GOAL := run

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

gcloud-create-cluster:
	@gcloud config set project ${GOOGLE_CLOUD_PROJECT}
	@gcloud config set compute/zone ${GOOGLE_CLOUD_ZONE}

	@gcloud container clusters create ${CLUSTER_NAME} --num-nodes=1 --enable-autoscaling --min-nodes 1 --max-nodes 10

gcloud-reserve-ip:
	@gcloud config set project ${GOOGLE_CLOUD_PROJECT}
	@gcloud config set compute/zone ${GOOGLE_CLOUD_ZONE}

	@gcloud compute addresses create ${APP_NAME} --global
	@gcloud compute addresses describe ${APP_NAME} --global
	@echo Create an A-Record in you DNS

gcloud-ssl-certificate:
	@gcloud config set project ${GOOGLE_CLOUD_PROJECT}
	@gcloud config set compute/zone ${GOOGLE_CLOUD_ZONE}

	@gcloud container clusters get-credentials ${CLUSTER_NAME}

	@kubectl apply -f certificate.yaml

gcloud-deploy:
	@gcloud config set project ${GOOGLE_CLOUD_PROJECT}
	@gcloud config set compute/zone ${GOOGLE_CLOUD_ZONE}

	@docker build -t gcr.io/${GOOGLE_CLOUD_PROJECT}/${APP_NAME}:v${APP_VERSION} .
	@docker push gcr.io/${GOOGLE_CLOUD_PROJECT}/${APP_NAME}:v${APP_VERSION}

	@gcloud container clusters get-credentials ${CLUSTER_NAME}

	@kubectl delete deployment ${APP_NAME}|| true
	@kubectl delete service ${APP_NAME} || true
	@kubectl delete ingress ${APP_NAME} || true

	@cat deployment.yaml | envsubst '${APP_NAME} ${BIGQUERY_TABLE} ${GOOGLE_CLOUD_PROJECT} ${APP_VERSION}' | kubectl apply -f -
	@cat service.yaml | envsubst '${APP_NAME}' | kubectl apply -f -
	@if [ -z '${DOMAIN_NAME}' ] ;\
	then cat ingress.yaml | envsubst '${APP_NAME}' | kubectl apply -f - ;\
	else cat ingress-reserved-ip-and-certificate.yaml| envsubst '${APP_NAME}' | kubectl apply -f - ; fi
