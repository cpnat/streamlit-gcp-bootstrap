import streamlit as st
from google.cloud import bigquery
import os

st.markdown("# Sample app")

client = bigquery.Client(project=os.environ.get('GOOGLE_CLOUD_PROJECT'))
query = 'SELECT * FROM `{}`'.format(os.environ.get('BIGQUERY_TABLE'))
df = client.query(query).to_dataframe()

st.dataframe(df)