# coding=utf-8
###############################################################################
#
# Script para enviar solicitações de transações para o RabbitMQ
#
# Parte do projeto do módulo Orquestração do treinamento Jornada Digital 
# ADA-Caixa
#
# Autor: Roberto Flavio Rezende
#

import json
import random
import os
from rabbitmq_connection import new_connection as rabbit_con, declare_queue
from redis_connection import new_connection as redis_con
from time import sleep
from datetime import datetime
from print_log import print_log


USUARIO = os.getenv('USUARIO_PADRAO')
SENHA = os.getenv('SENHA_PADRAO')
URL_RABBITMQ = os.getenv('URL_RABBITMQ')
URL_REDIS = os.getenv('URL_REDIS')

print_log('Iniciando a produção de transações...')

redis_client = redis_con(URL_REDIS)
rabbitmq_client = rabbit_con(USUARIO, SENHA, URL_RABBITMQ)

# Pega os números das contas no Redis
pegou_contas = False
while not pegou_contas:
    contas = redis_client.lrange('contas', 0, -1)
    pegou_contas = True if len(contas) > 0 else False
    sleep(5)

# Declara a fila para as transações
declare_queue(rabbitmq_client)

while True:
    # Sem o sleep o script iria gerar milhares de transações por segundo e moer a CPU.
    sleep(2)
    
    # Coloca todas as transacoes em Sao Paulo e 10% para Rio de Janeiro com o intuito de gerar "fraude"
    cidade = 'Rio de Janeiro' if random.random() < 0.1 else 'Sao Paulo'
    
    # Escolhe uma conta aleatoriamente para enviar a transação
    conta_origem = contas[random.randint(0, len(contas) - 1)]
    conta_destino = contas[random.randint(0, len(contas) - 1)]
    
    # Escolhe um valor aleatório para a transação.
    # Não serve para nada, mas porque não fazer?
    valor = random.randrange(100, 5000)
    
    timestamp = datetime.strftime(datetime.now(), '%Y-%m-%d %H:%M:%S')
    transacao = {'conta': conta_origem, 'transacao': {'conta_destino': conta_destino, 'valor': valor, 'cidade': cidade, 'timestamp': timestamp}}
    
    rabbitmq_client.basic_publish(exchange='transacoes', routing_key='solicitar', body=json.dumps(transacao))
    print_log(json.dumps(transacao))
    