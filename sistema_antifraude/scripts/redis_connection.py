# coding=utf-8
###############################################################################
#
# Módulo python para criar conexáo com o Redis.
# 
# Parte do projeto para o módulo Orquestração do treinamento Jornada Digital 
# ADA-Caixa
#
# Autor: Roberto Flavio Rezende
#
import redis
from time import sleep
from print_log import print_log


def new_connection(host='redis-service', porta=6379):
    """ Função para estabelecer a conexão com o Redis

    Args:
        host (str, optional): Endereço do Redis. Defaults to 'redis-service'.
        porta (int, optional): Porta de conexÃo com o Redis. Defaults to 6379.

    Returns:
        _type_: _description_
    """
    client = None
    while not client:
        try:
            client = redis.Redis(host=host, port=porta, decode_responses=True, )
        except:
            print_log('Aguardando Redis')
            sleep(5)
            pass
        
    return client