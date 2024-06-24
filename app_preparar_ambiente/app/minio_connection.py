# coding=utf-8
###############################################################################
#
# Módulo python para criar conexáo com o MinIO.
# 
# Parte do projeto para o módulo Orquestração do treinamento Jornada Digital 
# ADA-Caixa
#
# Autor: Roberto Flavio Rezende
#
from time import sleep
from minio import Minio
from print_log import print_log


def new_connection(usuario, senha, host='minio-service'):
    """ Função para estabelecer a conexão com o MinIO

    Args:
        usuario (str): Usuario de conexao no MinIO.
        senha (str): Senha de conexao ao MinIO.
        host (str): Endereço do MinIO. Defaults to 'minio-service'.

    Returns:
        object: Objeto de conexão ao MinIO
    """

    client = None
    while not client:
        try:
            client = Minio(f"{host}:9000", secure=False, access_key=usuario, secret_key=senha)
        except:
            print_log('Aguardando MinIO')
            sleep(5)
            pass
    
    return client