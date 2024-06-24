# Projeto Pipelines de CI e CD

## Treinamento Jornada Digital Caixa-ADA

### Descrição

Solução proposta para o projeto do módulo *Pipelines de CI e CD* do treinamento Jornada Digital Devops ADA-Caixa.  

Cada subdiretório contido neste repositório deverá estar em um repositório diferente para que as pipelines do Jenkins funcione corretamente.
- _criar_infraestrutura_: contém os arquivos necessários para a criação e atualização da infraestrutura do sistema de relatório de fraudes com Terraform.
- _app_preparar_ambiente_: contém os arquivos necessários para a configuração do ambiente para o início do processamento das movimentações bancárias e detecção de possíveis fraudes.
- _app_producer_: contém os arquivos para a geração das movimentações bancárias.
- _app_consumer_: contém os arquivos para verificaçÃo das movimentações, identificação das possíveis fraudes e geração do relatório.

O diretório projeto_pipeline contém os arquivos para a criação dos pipelines no Jenkins.

### Instruções

1. Criar os repositórios no GitHub com os conteúdos dos diretórios citados acima.
2. Editar os arquivos XML do Jenkins para refletir os novos repositórios do Github.
3. Criar as credenciais para o GitHub e Docker no Jenkins.

`Dashboard > Manage Jenkins > Credentials`

4. Criar as seguintes variáveis globais:

    `Dashboard > Manage Jenkins > System`
   
    - DOCKER_REGISTRY_CREDS: ID da credencial do docker criada no passo anterior
    - DOCKERHUB_APP_PROJETO_ADA_IMAGE: endereço do repositório com as imagens da aplicação. Neste caso, rfrezende/app-projeto-ada
      
5. Criar, em cada repositório do GitHub, os webhooks apontando para o Jenkins. Deixar marcado apenas `Pull Requests`.

### Melhorias futuras
- Separar os arquivos do Terraform para gerenciar os elementos da solução de maneira independente.
  
  Atualmente é necessário recriar todo o ambiente a cada modificação.
