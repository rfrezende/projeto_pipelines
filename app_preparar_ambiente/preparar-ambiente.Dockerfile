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

WORKDIR /app

COPY ../app/minio_connection.py .
COPY ../app/rabbitmq_connection.py .
COPY ../app/redis_connection.py .
COPY ../app/print_log.py .
COPY ../app/preparar_ambiente.py app.py

ENTRYPOINT python app.py
