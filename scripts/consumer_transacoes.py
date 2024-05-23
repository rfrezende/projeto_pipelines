# coding=utf-8
###############################################################################
#
# Script para processar as solicitações de transações.
#  - Retira do RabbitMQ e grava no Redis.
#  - Notifica que houve movimentação na conta
# 
# Parte do projeto do módulo Orquestração do treinamento Jornada Digital 
# ADA-Caixa
#
# Autor: Roberto Flavio Rezende
#
import json
import os
import requests
from rabbitmq_connection import new_connection as rabbit_con, declare_queue
from minio_connection import new_connection as minio_con
from redis_connection import new_connection as redis_con
from datetime import datetime, timedelta
from print_log import print_log


USUARIO = os.getenv('USUARIO_PADRAO')
SENHA = os.getenv('SENHA_PADRAO')
URL_RABBITMQ = os.getenv('URL_RABBITMQ')
URL_REDIS = os.getenv('URL_REDIS')
URL_MINIO = os.getenv('URL_MINIO')

print_log('Iniciando o consumo das filas...')

minio_client = minio_con(USUARIO, SENHA, URL_MINIO)
rabbitmq_client = rabbit_con(USUARIO, SENHA, URL_RABBITMQ)
redis_client = redis_con(URL_MINIO)

bucket_name = 'relatorios-fraudes'
formato_timestamp = '%Y-%m-%d %H:%M:%S'
duas_horas = timedelta(hours=2)
caminho = os.getcwd()

def callback(ch, method, properties, body):
    dado = json.loads(body.decode('utf-8'))
    nu_conta = dado['conta']
    transacao_atual = dado['transacao']

    # Pega a transação anterior
    get_transacao_anterior = redis_client.json().get(nu_conta, '$.transacoes[-1]')
    
    if len(get_transacao_anterior) > 0:
        transacao_anterior = get_transacao_anterior[0]
    else:
        transacao_anterior = transacao_atual
        
    # Grava a transação atual no Redis
    redis_client.json().arrappend(nu_conta, '$.transacoes', transacao_atual)

    # Verifica os parametros para gerar o relatorio
    timestamp_anterior = datetime.strptime(transacao_anterior['timestamp'], formato_timestamp)
    timestamp_atual = datetime.strptime(transacao_atual['timestamp'], formato_timestamp)
    diferenca_de_horario = timestamp_atual - timestamp_anterior
    
    if transacao_anterior['cidade'] != transacao_atual['cidade'] and diferenca_de_horario < duas_horas:
        # Caso seja considerado fraude, monta e grava o relatório.        
        print_log(f'----> evidencia de fraude:\n Conta: {nu_conta}\n Transação anterior:\t{transacao_anterior}\n Transação atual:\t{transacao_atual}')
        
        timestamp_relatorio = datetime.strftime(datetime.now(), '%Y%m%d%H%M%S')
        objeto_relatorio = f'relatorio_{nu_conta}_{timestamp_relatorio}.txt'
        
        with open(f'{caminho}{objeto_relatorio}', 'w') as f:
            f.write(f'# Relatório de suspeita de fraude\n\n'
                    f'- Conta: {nu_conta}\n\n- Transação suspeita: \n'
                    f'  - Conta destino: {transacao_atual['conta_destino']}\n'
                    f'  - Cidade:\t{transacao_atual['cidade']}\n'
                    f'  - Valor:\tR$ {transacao_atual['valor']}\n'
                    f'  - Timestamp:\t{transacao_atual['timestamp']}\n\n'
                    f'- Transação anterior\n'
                    f'  - Conta destino: {transacao_anterior['conta_destino']}\n'
                    f'  - Cidade:\t{transacao_anterior['cidade']}\n'
                    f'  - Valor:\tR$ {transacao_anterior['valor']}\n'
                    f'  - Timestamp:\t{transacao_anterior['timestamp']}\n\n'
                    f'- Intervalo entre as transações: {diferenca_de_horario}\n')
        
        minio_client.fput_object(bucket_name, objeto_relatorio, f'{caminho}{objeto_relatorio}')
        
        url = minio_client.get_presigned_url('GET', bucket_name, objeto_relatorio)
        
        # A substituicao é porque a URL vem com a conexão usada, que é o nome do container do MinIO
        get_ip_externo = requests.get('http://api.ipify.org')
        ip_externo = get_ip_externo.text
        url_externa = url.split('?')[0].replace('localhost', ip_externo)
        print(f'URL para o relatório: {url_externa}\n')
        
        os.remove(f'{caminho}{objeto_relatorio}')


# Declara a fila para as transações
declare_queue(rabbitmq_client)

# Inicia o consumo
rabbitmq_client.basic_consume(queue='transacoes_solicitadas', on_message_callback=callback, auto_ack=True)
rabbitmq_client.start_consuming()
