# base image
FROM ghcr.io/dbt-labs/dbt-bigquery:1.7.2
# create and set working folder for dbt
WORKDIR /dbt
# copy code
COPY . /dbt/
# install dependencies
RUN dbt deps
# set dbt entrypoint
ENTRYPOINT ["dbt"]
