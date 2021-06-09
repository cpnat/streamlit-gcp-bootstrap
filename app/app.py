import streamlit as st
from google.cloud import bigquery
import os

st.markdown("# Sample app")

client = bigquery.Client(project=os.environ.get('GOOGLE_CLOUD_PROJECT'))
query = 'SELECT * FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`')
df = client.query(query).to_dataframe()

st.dataframe(df)