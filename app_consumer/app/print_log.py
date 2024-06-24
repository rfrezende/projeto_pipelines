# coding=utf-8
###############################################################################
#
# Módulo para imprimir no log do pod
#
# Parte do projeto do módulo Orquestração do treinamento Jornada Digital 
# ADA-Caixa
#
# Autor: Roberto Flavio Rezende
#
from datetime import datetime

def print_log(msg):
    """ Print no log do Docker

    Args:
        msg (str): Mensagem a ser impressa
    """
    mascara_timestamp = '%Y-%m-%d %H:%M:%S'
    timestamp = datetime.strftime(datetime.now(), mascara_timestamp)
    print(f'{timestamp} {msg}')