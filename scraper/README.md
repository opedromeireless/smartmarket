# Coleta SmartMarket — piloto Fort

O adaptador preserva os campos JSON/CSV do piloto original e adiciona um relatório por execução. Não normaliza identidade canônica nem altera disponibilidade no catálogo nesta etapa.

## Testes e demonstração sem rede

Requer Python 3.10+ (validado localmente com 3.11 e 3.14). Na raiz do projeto:

```sh
python3 -m unittest discover -s scraper/tests -v
python3 scraper/coleta_fort_atacadista.py --fixture scraper/tests/fixtures/fort_valido.json --output-dir scraper/output/valido
python3 scraper/coleta_fort_atacadista.py --fixture scraper/tests/fixtures/fort_parcial.json --output-dir scraper/output/parcial
```

O último comando retorna **2** deliberadamente: uma execução parcial não é sucesso completo. Fixtures são sintéticas e nunca representam preços atuais.

## Contrato de extração v1

JSON é uma lista de objetos; CSV tem as mesmas colunas, na ordem abaixo. Campos opcionais continuam presentes com `null` em JSON/célula vazia em CSV. Não há tradução silenciosa de moeda, embalagem, marca ou identidade.

| Campo | Contrato |
|---|---|
| nome_bruto | string não vazia, preservada como recebida |
| preco | número finito estritamente positivo; promocional se presente, senão preço normal |
| preco_normal | número finito positivo, ou null se não informado |
| em_promocao | booleano/null original `pricing.promotion`, false quando ausente; outros tipos rejeitados; não usado como prova de elegibilidade |
| marca | `brandName` original, ou null |
| categoria | chave amigável da configuração |
| slug | original ou null |
| id_produto_origem | ID original ou null; não é ID canônico do banco |
| supermercado | Fort Atacadista |
| data_coleta | ISO8601 UTC com `+00:00`, precisão de segundos |

Decisões de validação: promoção ausente ou nula usa preço normal; promoção zero/negativa/não numérica rejeita o item, mesmo com preço normal válido. Preço normal fornecido e inválido também rejeita o item. Tokens numéricos HTTP/fixture são lidos com Decimal. Campos monetários são validados com Decimal e exportados como números JSON para compatibilidade somente quando a representação decimal não perde precisão; o consumidor financeiro deve usar Decimal, nunca aritmética float. Não se impõe arredondamento ou limite de preço comercial nesta etapa. String numérica com ponto é aceita; `R$ 1,00` não é interpretada automaticamente. Nome vazio/item não objeto/pricing inválido são rejeitados individualmente.

Coleta é amostra de no máximo 20 itens aceitos por categoria. Limite adicional de 10 páginas evita laço sem fim quando todos os itens são rejeitados. Não deduplica identidades nem marca produto como indisponível porque saiu dessa amostra. Uma falha de página encerra só essa categoria, preserva itens já aceitos e permite a categoria seguinte. Não há retry HTTP automático ainda.

## Saídas e resultados

- `produtos_coletados.json` e `.csv`: itens aceitos.
- `relatorio_coleta.json`: `status`, `aceitos`, `falhas` com categoria/página/índice/motivo, `saida_atualizada`, modo fixture/http, empresa/loja de origem e instante UTC.
- Código 0: concluído sem rejeição; 2: parcial com itens aceitos; 1: falha total/fixture inválida.

Sem itens aceitos, os arquivos anteriores ficam preservados e `saida_atualizada=false`; consumidores devem ler o relatório e nunca tratar arquivos antigos como dados novos. Uma fixture inválida falha antes da geração do relatório: verificar sempre o código de saída. Cada arquivo é substituído atomicamente, mas o conjunto de três arquivos não é uma transação. Use diretório novo por execução no pipeline. Logs não incluem corpos de resposta nem dados brutos do item. Erro local de disco propaga exceção e código não zero.

## HTTP (não executado nesta entrega)

```sh
python3 -m venv scraper/.venv
scraper/.venv/bin/python -m pip install -r scraper/requirements.txt
scraper/.venv/bin/python scraper/coleta_fort_atacadista.py --output-dir scraper/output/http
```

Sem `--fixture`, o comando acessa a fonte real. Antes disso, validar autorização/regras atuais de uso da fonte e confirmar a loja 1585/empresa 334. Timeout 10s; pausa 1,5s entre páginas/categorias. A dependência HTTP usa faixa de versão, não lock de ambiente. Os testes offline não instalam dependências nem acessam sites. Elegibilidade de promoção, unidade monetária, regras de equivalência e segunda rede dependem de contrato com o time; o campo promocional é dado bruto.

## Normalização e pipeline local

A entrega ampliada, comandos PostgreSQL, resultados por cartão e limitações estão em [ENTREGA-JOAO.md](ENTREGA-JOAO.md). O adaptador extrai dados brutos; normalização e ingestão ficam nos módulos próprios, testados separadamente.

Revisão v2: moeda contratada BRL, sem câmbio; declarações currency/moeda incompatíveis são rejeitadas. O legado sem campo de moeda depende da confirmação da fonte. A carga usa schema auxiliar v2 e exige base fixture nova, sem migração dos dados da primeira entrega. Veja o guia para os 69 testes finais/88% de cobertura e a distinção entre comando manual e agendamento ainda ausente.
