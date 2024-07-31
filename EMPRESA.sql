CREATE database EmpresaXYZ
USE EmpresaXYZ

-- Deleta as tabelas e suas restrições, execute duas vezes (dropar as views primeiro)
DECLARE @TableName NVARCHAR(MAX)
DECLARE @ConstraintName NVARCHAR(MAX)
DECLARE Constraints CURSOR FOR
SELECT TABLE_NAME, CONSTRAINT_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE

OPEN Constraints
FETCH NEXT FROM Constraints INTO @TableName, @ConstraintName

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC('ALTER TABLE [' + @TableName + '] DROP CONSTRAINT [' + @ConstraintName + ']')
    FETCH NEXT FROM Constraints INTO @TableName, @ConstraintName
END

CLOSE Constraints
DEALLOCATE Constraints

DECLARE Tables CURSOR FOR
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES

OPEN Tables
FETCH NEXT FROM Tables INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC('DROP TABLE [' + @TableName + ']')
    FETCH NEXT FROM Tables INTO @TableName
END

CLOSE Tables
DEALLOCATE Tables

-- Criação das tabelas e suas respectivas restrições

CREATE TABLE estado(
    id int identity(1,1),
    sigla char(2) NOT NULL,
    nome varchar(30) NOT NULL,
    CONSTRAINT pk_estado PRIMARY KEY (id)
)

CREATE TABLE cidade(
    id int identity(1,1),
    nome varchar(30) NOT NULL,
    idEstado int NOT NULL,
    CONSTRAINT pk_cidade PRIMARY KEY (id),
    CONSTRAINT fk_cidade FOREIGN KEY (idEstado) REFERENCES estado(id)
)

CREATE TABLE tipologradouro(
    idTipoLogradouro varchar(3) NOT NULL,
    tipo varchar(30) NOT NULL,
    CONSTRAINT pk_tipologradouro PRIMARY KEY (idTipoLogradouro)
)

CREATE TABLE endereco(
    idEndereco int identity(1,1),
    CEP int NOT NULL,
    idCidade int NOT NULL,
    idTipoLogradouro varchar(3) NOT NULL,
    CONSTRAINT pk_endereco PRIMARY KEY (idEndereco),
    CONSTRAINT fk_endereco FOREIGN KEY (idCidade) REFERENCES cidade(id),
    CONSTRAINT fk2_endereco FOREIGN KEY (idTipoLogradouro) REFERENCES tipologradouro(idTipoLogradouro)
)

CREATE TABLE pessoa(
    nome varchar(100) NOT NULL,
    email varchar(100) NOT NULL,
    CPF varchar(20) NOT NULL,
    RG varchar(20) NOT NULL,
    orgaomissorRG varchar(50) NOT NULL,
    senha varchar(10) DEFAULT '123456',
    idEndereco int NOT NULL,
    CONSTRAINT pk_pessoa PRIMARY KEY(CPF),
    CONSTRAINT fk2_pessoa FOREIGN KEY(idEndereco) REFERENCES endereco(idEndereco),
    CHECK (email LIKE '%_@_%_.__%'),
    CHECK (CPF LIKE '___.___.___-__')
)

CREATE TABLE tb_rg(
    RG varchar(20) NOT NULL,
    CPF varchar(20) NOT NULL,
    CONSTRAINT fk_rg FOREIGN KEY(CPF) REFERENCES pessoa(CPF)
)

CREATE TABLE telefone(
    numero varchar(9) NOT NULL,
    tipo char(1) DEFAULT 'F',
    CPF varchar(20) NOT NULL,
    CONSTRAINT pk_telefone PRIMARY KEY(numero),
    CONSTRAINT fk_telefone FOREIGN KEY(CPF) REFERENCES pessoa(CPF),
    CHECK (tipo IN ('F', 'M'))
)

CREATE TABLE empresa(
    nome varchar(50) NOT NULL,
    razaosocial varchar(100) NOT NULL,
    idEndereco int NOT NULL,
    CNPJ varchar(20) NOT NULL,
    email varchar(50) NOT NULL,
    idResponsavel varchar(20) NOT NULL,
    CONSTRAINT pk_empresa PRIMARY KEY(CNPJ),
    CONSTRAINT fk_empresa FOREIGN KEY(idEndereco) REFERENCES endereco(idEndereco),
    CONSTRAINT fk2_empresa FOREIGN KEY(idResponsavel) REFERENCES pessoa(CPF),
    CHECK (email LIKE '%_@_%_.__%'),
    CHECK (CNPJ LIKE '__.___.___/____-__')
)

CREATE TABLE tbr_pessoa_empresa(
    id_tbr_pessoa_empresa int identity(1,1),
    CPF varchar(20) NOT NULL,
    CNPJ varchar(20) NOT NULL,
    CONSTRAINT pk_tbr_pessoa_empresa PRIMARY KEY(id_tbr_pessoa_empresa),
    CONSTRAINT fk1_tbr_pessoa_empresa FOREIGN KEY(CPF) REFERENCES pessoa(CPF),
    CONSTRAINT fk2_tbr_pessoa_empresa FOREIGN KEY(CNPJ) REFERENCES empresa(CNPJ)
)

CREATE TABLE projeto(
    situacao varchar(15) DEFAULT('Em cadastro'),
    numero varchar(17) NOT NULL,
    CNPJ varchar(20) NOT NULL,
    CPF varchar(20) NOT NULL,
    tipo char(2) NOT NULL,
    inicio datetime NOT NULL,
    fim datetime NOT NULL,
    CONSTRAINT pk_projeto PRIMARY KEY(numero),
    CONSTRAINT fk_projeto FOREIGN KEY(CNPJ) REFERENCES empresa(CNPJ),
    CONSTRAINT fk2_projeto FOREIGN KEY(CPF) REFERENCES pessoa(CPF),
    CONSTRAINT ck_data_projeto CHECK (inicio < fim),
    CONSTRAINT ck_situacao_projeto CHECK (situacao IN ('Em Cadastro', 'Ativo', 'Cancelado'))
)

CREATE TABLE tbr_pessoa_projeto(
    id_tbr_pessoa_projeto int identity(1,1),
    CPF varchar(20) NOT NULL,
    numero varchar(17) NOT NULL,
    CONSTRAINT fk1_pessoa_projeto FOREIGN KEY(CPF) REFERENCES pessoa(CPF),
    CONSTRAINT fk2_pessoa_projeto FOREIGN KEY(numero) REFERENCES projeto(numero)
)

CREATE TABLE meta(
    id int identity(1,1),
    numero int NOT NULL,
    projeto varchar(17) NOT NULL,
    CONSTRAINT pk_meta PRIMARY KEY(id),
    CONSTRAINT fk_meta FOREIGN KEY(projeto) REFERENCES projeto(numero)
)

CREATE TABLE etapa(
    id int identity(1,1),
    numero int NOT NULL,
    meta int NOT NULL,
    dataPrevista datetime NOT NULL,
    unidadeControle varchar(5) DEFAULT ('%'),
    Programado numeric(5,2) NOT NULL,
    Executado numeric(5,2) NOT NULL,
    CONSTRAINT pk_etapa PRIMARY KEY(id),
    CONSTRAINT fk_etapa FOREIGN KEY(meta) REFERENCES meta(id)
)

CREATE TABLE recursoFinanceiro(
    id int identity(1,1),
    valorDisponivel numeric(8,2) NOT NULL,
    qtParcelas int NOT NULL,
    financiador varchar(20) NOT NULL,
    tipo char(1) NOT NULL,
    etapa int NOT NULL,
    CHECK (tipo IN('P', 'T', 'F', 'B')),
    CONSTRAINT pk_recursoFinanceiro PRIMARY KEY(id),
    CONSTRAINT fk_recursoFinanceiro FOREIGN KEY(financiador) REFERENCES empresa(CNPJ),
    CONSTRAINT fk2_recursoFinanceiro FOREIGN KEY(etapa) REFERENCES etapa(id)
)

CREATE TABLE docPagamento(
    id int identity(1,1),
    numero varchar(50) NOT NULL,
    valor numeric(8,2) NOT NULL,
    data datetime NOT NULL,
    responsavelCPF varchar(20),
    responsavelCNPJ varchar(20),
    recursoFinanceiro int,
    CONSTRAINT pk_docPagamento PRIMARY KEY(id),
    CONSTRAINT fk_docPagamento FOREIGN KEY(recursoFinanceiro) REFERENCES recursoFinanceiro(id),
    CONSTRAINT fk2_docPagamento FOREIGN KEY(responsavelCPF) REFERENCES pessoa(CPF),
    CONSTRAINT fk3_docPagamento FOREIGN KEY(responsavelCNPJ) REFERENCES empresa(CNPJ)
)

CREATE TABLE tituloCredito(
    nome varchar(15) DEFAULT ('Nota Fiscal'),
    sigla char(3) DEFAULT ('NF'),
    CONSTRAINT pk_tituloCredito PRIMARY KEY(sigla)
)

CREATE TABLE despesas(
    id int identity(1,1),
    nome varchar(50) NOT NULL,
    identificacao int NOT NULL,
    docPagamento int NOT NULL,
    tituloCredito char(3) DEFAULT ('NF'),
    numeroCredito int,
    etapa int NOT NULL,
    numero varchar(17) NOT NULL,
    CONSTRAINT pk_despesas PRIMARY KEY(id),
    CONSTRAINT fk_despesas FOREIGN KEY(docPagamento) REFERENCES docPagamento(id),
    CONSTRAINT fk2_despesas FOREIGN KEY(tituloCredito) REFERENCES tituloCredito(sigla),
    CONSTRAINT fk3_despesas FOREIGN KEY(etapa) REFERENCES etapa(id),
    CONSTRAINT fk4_despesas FOREIGN KEY(numero) REFERENCES projeto(numero)
)

-- Zona de testes

-- Triggers e stored procedures

CREATE TRIGGER TRG_ativo_para_emcadastro ON projeto
AFTER UPDATE 
AS 
BEGIN
    DECLARE @situacaoAntiga varchar(15),
            @situacaoNova varchar(15),
            @numero varchar(17)

    SELECT @situacaoAntiga = deleted.situacao,
           @situacaoNova = projeto.situacao,
           @numero = projeto.numero 
    FROM deleted 
    JOIN projeto ON projeto.numero = deleted.numero

    IF(@situacaoAntiga = 'Ativo' AND @situacaoNova = 'Em Cadastro')
    BEGIN 
        ROLLBACK TRANSACTION
        RAISERROR('Projeto ativo não pode voltar para a fase em cadastro',16,1)
    END
END

CREATE TRIGGER TRG_dataPrev_maiorQue_fim ON etapa
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @dataPrevista datetime,
            @dataFimProjeto datetime

    SELECT @dataPrevista = dataPrevista, 
           @dataFimProjeto = projeto.fim 
    FROM