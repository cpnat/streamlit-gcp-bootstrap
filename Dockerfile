FROM python:3.7.8-slim

EXPOSE 8080

# Install Python dependencies
RUN pip install -U pip
COPY requirements.txt app/requirements.txt
RUN pip install -r app/requirements.txt

# Copy into a directory of its own (so it isn't in the toplevel dir)
COPY app /app
WORKDIR /app

# Run it!
ENTRYPOINT ["streamlit", "run", "app.py", "--server.port=8080", "--server.address=0.0.0.0"]
