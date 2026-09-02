-- ============================================================
-- SmartMarket - Script DDL
-- PostgreSQL
-- ============================================================

-- =========================
-- Tabela: usuario
-- =========================
CREATE TABLE usuario (
    id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    senha_rash VARCHAR(70) NOT NULL,
    papel VARCHAR(20) NOT NULL DEFAULT 'CONSUMIDOR',

    CONSTRAINT ck_usuario_papel
        CHECK (papel IN ('CONSUMIDOR', 'ADMIN'))
);

-- =========================
-- Tabela: produto
-- =========================
CREATE TABLE produto (
    id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    marca VARCHAR(120) NOT NULL,
    categoria VARCHAR(120),
    unidade VARCHAR(20),
    quantidade NUMERIC(10,3),
    codigo_barras VARCHAR(30)
);

-- =========================
-- Tabela: mercado
-- =========================
CREATE TABLE mercado (
    id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    rede VARCHAR(120) NOT NULL,
    endereco VARCHAR(120) NOT NULL,
    lat VARCHAR(20),
    lng VARCHAR(20)
);

-- =========================
-- Tabela: lista_compras
-- =========================
CREATE TABLE lista_compras (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    nome VARCHAR(120) NOT NULL,
    criada_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_lista_compras_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuario(id)
        ON DELETE CASCADE
);

-- =========================
-- Tabela: item_lista
-- =========================
CREATE TABLE item_lista (
    id BIGSERIAL PRIMARY KEY,
    lista_id BIGINT NOT NULL,
    produto_id BIGINT NOT NULL,
    quantidade NUMERIC(10,3),

    CONSTRAINT fk_item_lista_lista
        FOREIGN KEY (lista_id)
        REFERENCES lista_compras(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_item_lista_produto
        FOREIGN KEY (produto_id)
        REFERENCES produto(id)
        ON DELETE CASCADE
);

-- =========================
-- Tabela: favorito
-- =========================
CREATE TABLE favorito (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    mercado_id BIGINT NOT NULL,

    CONSTRAINT fk_favorito_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuario(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_favorito_mercado
        FOREIGN KEY (mercado_id)
        REFERENCES mercado(id)
        ON DELETE CASCADE
);

-- =========================
-- Tabela: preco
-- =========================
CREATE TABLE preco (
    id BIGSERIAL PRIMARY KEY,
    produto_id BIGINT NOT NULL,
    mercado_id BIGINT NOT NULL,
    valor NUMERIC(10,3),
    disponivel BOOLEAN NOT NULL DEFAULT TRUE,
    coletado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    origem VARCHAR(120) NOT NULL,
    nome_bruto VARCHAR(180),

    CONSTRAINT fk_preco_produto
        FOREIGN KEY (produto_id)
        REFERENCES produto(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_preco_mercado
        FOREIGN KEY (mercado_id)
        REFERENCES mercado(id)
        ON DELETE CASCADE
);

-- =========================
-- Tabela: promocao
-- =========================
CREATE TABLE promocao (
    id BIGSERIAL PRIMARY KEY,
    produto_id BIGINT NOT NULL,
    mercado_id BIGINT NOT NULL,
    valor_promocional NUMERIC(10,3),
    data_inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    data_fim TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    coletado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    origem VARCHAR(120) NOT NULL,

    CONSTRAINT fk_promocao_produto
        FOREIGN KEY (produto_id)
        REFERENCES produto(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_promocao_mercado
        FOREIGN KEY (mercado_id)
        REFERENCES mercado(id)
        ON DELETE CASCADE
);

-- =========================
-- Tabela: alerta
-- =========================
CREATE TABLE alerta (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    produto_id BIGINT NOT NULL,
    preco_alvo NUMERIC(10,3) NOT NULL,

    CONSTRAINT fk_alerta_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuario(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_alerta_produto
        FOREIGN KEY (produto_id)
        REFERENCES produto(id)
        ON DELETE CASCADE
);
