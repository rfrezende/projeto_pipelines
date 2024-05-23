# coding=utf-8
###############################################################################
#
# Script para preparar o ambiente do Projeto
#
# Parte do projeto do módulo Orquestração do treinamento Jornada Digital 
# ADA-Caixa
#
# Autor: Roberto Flavio Rezende
#
import json
import random
import os
from time import sleep
from minio_connection import new_connection as minio_con
from rabbitmq_connection import new_connection as rabbitmq_con
from redis_connection import new_connection as redis_con
from print_log import print_log


USUARIO = os.getenv('USUARIO_PADRAO')
SENHA = os.getenv('SENHA_PADRAO')
URL_RABBITMQ = os.getenv('URL_RABBITMQ')
URL_REDIS = os.getenv('URL_REDIS')
URL_MINIO = os.getenv('URL_MINIO')


def create_rabbitmq():
    """ Prepara o ambiente do RabbitMQ.
        Cria a exchange, a fila para as transações e faz o bind entre elas.
    """
    print_log(f'Preparando ambiente do RabbitMQ. {URL_RABBITMQ}')

    rabbitmq_client = rabbitmq_con(USUARIO, SENHA, URL_RABBITMQ)

    rabbitmq_client.exchange_declare(exchange='transacoes', exchange_type='direct')

    print_log(f'Ambiente do RabbitMQ pronto.')


def create_minio():
    """ Prepara o ambiente do MinIO.
        Cria o bucket para receber os relatórios e configura a política de segurança.
    """
    print_log('Preparando ambiente do MinIO.')
    
    minio_client = minio_con(USUARIO, SENHA, URL_MINIO)
        
    bucket_name = 'relatorios-fraudes'

    bucket_found = minio_client.bucket_exists(bucket_name)
    if not bucket_found:
        print_log(f'Bucket {bucket_name} não existe. Criando.')
        minio_client.make_bucket(bucket_name)

        # Permite a leitura dos relatórios sem necessidade de autenticação.
        policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": [
                            "*"
                        ]
                    },
                    "Action": [
                        "s3:GetObject"
                    ],
                    "Resource": [
                        f"arn:aws:s3:::{bucket_name}/*"
                    ]
                }
            ],
        }
        
        minio_client.set_bucket_policy(bucket_name, json.dumps(policy))

        print_log(f'Bucket {bucket_name} criado no MinIO.')
    
    print_log(f'Ambiente do MinIO pronto.')
    
    
def create_redis():
    """ Prepara o ambiente do Redis.
        Gera 20 contas aleatórias.
        Cria uma lista com as contas no Redis.
        Cria uma entrada do tipo lista para cada conta no Redis
    """
    redis_client = redis_con(URL_REDIS)

    print_log(f'Preparando o ambiente do Redis.')

    quantidade_de_contas = 20

    # Função para gerar o número da conta
    criar_conta = lambda x: f'{random.randrange(10000, 99999)}-{random.randrange(1, 9)}'
    lista_contas = [criar_conta(None) for i in range(quantidade_de_contas)]
    
    redis_client.rpush('contas', *lista_contas)

    print_log(f'Contas a serem criadas: {lista_contas}')

    for conta in lista_contas:
        redis_client.json().set(conta, '$', {'transacoes': []})

    print_log(f'Ambiente do Redis pronto.')
    

def main():
    """ Main ;)
    """
    print_log('Preparando o ambiente do projeto.')
    create_rabbitmq()
    create_minio()
    create_redis()
    print_log('Ambiente do projeto pronto para utilização.')
    
    while True:
        sleep(90)
        
if __name__ == '__main__':
    main()
    