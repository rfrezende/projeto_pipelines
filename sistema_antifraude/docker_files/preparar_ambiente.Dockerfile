##################################################################################
#
# Dockerfile para criar a imagem da aplicação de cpreparação do ambiente
#
# Parte do projeto do módulo Orquestração do treinamento Jornada Digital ADA-Caixa
#
# Autor: Roberto Flavio Rezende
#

FROM python:3.12-alpine

RUN pip install minio pika redis

WORKDIR /scripts

COPY ../scripts/minio_connection.py .
COPY ../scripts/rabbitmq_connection.py .
COPY ../scripts/redis_connection.py .
COPY ../scripts/print_log.py .
COPY ../scripts/preparar_ambiente.py app.py

ENTRYPOINT python app.py
