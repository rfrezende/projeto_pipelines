###################################################################################
#
# Dockerfile para criar a imagem da aplicação de produção das transações bancárias
#
# Parte do projeto do módulo Orquestração do treinamento Jornada Digital ADA-Caixa
#
# Autor: Roberto Flavio Rezende
#
FROM python:3.12-alpine

RUN pip install minio pika redis

WORKDIR /app

COPY ../app/rabbitmq_connection.py .
COPY ../app/redis_connection.py .
COPY ../app/print_log.py .
COPY ../app/producer_transacoes.py app.py

ENTRYPOINT python app.py