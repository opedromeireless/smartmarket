"""
SmartMarket - Scraper Fort Atacadista
--------------------------------------
Coleta produtos básicos via a API de categoria usada pelo próprio site
(sense.osuper.com.br), navegando por categoria - NÃO usa o endpoint de
busca (/search), que é desencorajado pelo robots.txt do fortatacadista.com.br.

Saída: dois arquivos, um .json e um .csv, com os campos:
nome_bruto, preco, data_coleta (+ campos extras úteis pra normalização depois).
"""

import requests
import time
import json
import csv
from datetime import datetime

# ---------------------------------------------------------------------------
# CONFIGURAÇÃO: adicione mais categorias aqui conforme forem descobertas
# (nome amigável -> ID de categoria encontrado no DevTools/Network)
# ---------------------------------------------------------------------------
CATEGORIAS = {
    "Graos_Arrozes_Feijoes": "1815215",
    "Leites": "1815285",
    # "Oleos": "XXXXXXX",
    # "Cafes": "XXXXXXX",
    # "Detergentes": "XXXXXXX",
    # "Papel_Higienico": "XXXXXXX",
}

COMPANY_ID = "334"
STORE_ID = "1585"
BASE_URL = f"https://sense.osuper.com.br/{COMPANY_ID}/{STORE_ID}/category"

# Limite de produtos coletados POR categoria (mantém a coleta dentro do
# escopo de MVP de 20-40 produtos no total, conforme o documento oficial)
LIMITE_POR_CATEGORIA = 20
TAMANHO_PAGINA = 10  # quantos produtos pedir por requisição
PAUSA_ENTRE_REQUISICOES = 1.5  # segundos - educado com o servidor

HEADERS = {
    # Identifica o script de forma honesta (projeto acadêmico), sem se
    # disfarçar de navegador comum
    "User-Agent": "SmartMarketBot/0.1 (projeto academico Codifica/+praTI; contato: dev.davicardozo@gmail.com)"
}


def coletar_categoria(nome_categoria: str, categoria_id: str) -> list[dict]:
    """Busca produtos de uma categoria, paginando até atingir o limite."""
    produtos = []
    origem = 0

    while len(produtos) < LIMITE_POR_CATEGORIA:
        params = {
            "sortField": "sales_count",
            "sortOrder": "desc",
            "size": TAMANHO_PAGINA,
            "from": origem,
        }
        url = f"{BASE_URL}/{categoria_id}"

        resposta = requests.get(url, headers=HEADERS, params=params, timeout=10)
        resposta.raise_for_status()
        dados = resposta.json()

        hits = dados.get("hits", [])
        if not hits:
            break  # acabaram os produtos dessa categoria

        agora = datetime.now().isoformat(timespec="seconds")

        for item in hits:
            pricing = item.get("pricing", {}) or {}
            produtos.append({
                "nome_bruto": item.get("name"),
                "preco": pricing.get("promotionalPrice", pricing.get("price")),
                "preco_normal": pricing.get("price"),
                "em_promocao": pricing.get("promotion", False),
                "marca": item.get("brandName"),
                "categoria": nome_categoria,
                "slug": item.get("slug"),
                "id_produto_origem": item.get("id"),
                "supermercado": "Fort Atacadista",
                "data_coleta": agora,
            })

        origem += TAMANHO_PAGINA

        if not dados.get("hasNext", False):
            break

        time.sleep(PAUSA_ENTRE_REQUISICOES)

    return produtos[:LIMITE_POR_CATEGORIA]


def main():
    todos_produtos = []

    for nome_categoria, categoria_id in CATEGORIAS.items():
        print(f"Coletando categoria: {nome_categoria} (id={categoria_id})...")
        produtos = coletar_categoria(nome_categoria, categoria_id)
        print(f"  -> {len(produtos)} produtos coletados.")
        todos_produtos.extend(produtos)
        time.sleep(PAUSA_ENTRE_REQUISICOES)

    if not todos_produtos:
        print("Nenhum produto coletado. Verifique os IDs de categoria e a conexão.")
        return

    # --- Salvar em JSON ---
    with open("produtos_coletados.json", "w", encoding="utf-8") as f:
        json.dump(todos_produtos, f, ensure_ascii=False, indent=2)

    # --- Salvar em CSV ---
    campos = list(todos_produtos[0].keys())
    with open("produtos_coletados.csv", "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=campos)
        writer.writeheader()
        writer.writerows(todos_produtos)

    print(f"\nTotal coletado: {len(todos_produtos)} produtos.")
    print("Arquivos gerados: produtos_coletados.json e produtos_coletados.csv")


if __name__ == "__main__":
    main()
