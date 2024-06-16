#!/usr/bin/env bash
##################################################################################
#
# Script para build do ambiente de teste
#
# Parte do projeto do módulo Orquestração do treinamento Jornada Digital ADA-Caixa
#
# Autor: Roberto Flavio Rezende
#

set -e

docker build --file ./docker_files/preparar_ambiente.Dockerfile --tag rfrezende/app-projeto-ada:preparar-ambiente .
docker push rfrezende/app-projeto-ada:preparar-ambiente

docker build --file ./docker_files/producer.Dockerfile --tag rfrezende/app-projeto-ada:producer .
docker push rfrezende/app-projeto-ada:producer

docker build --file ./docker_files/consumer.Dockerfile --tag rfrezende/app-projeto-ada:consumer .
docker push rfrezende/app-projeto-ada:consumer
