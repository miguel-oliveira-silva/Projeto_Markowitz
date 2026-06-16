# 📈 Sistema Markovitz — Portfolio Optimizer

Sistema de microsserviços em **Spring Boot** que implementa a **Teoria Moderna do Portfólio de Harry Markowitz** para otimização de carteiras de investimento.

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    SISTEMA MARKOVITZ                        │
│                                                             │
│  ┌─────────────┐      ┌──────────────┐                     │
│  │ user-service │      │ asset-service │                    │
│  │  porta 8081  │      │  porta 8082   │                    │
│  │             │      │              │                     │
│  │ - Cadastro  │      │ - Ativos     │                     │
│  │ - Login     │      │ - Preços     │                     │
│  │ - Perfil    │      │ - Stats μ/σ  │                     │
│  └──────┬──────┘      └──────┬───────┘                     │
│         │                    │                             │
│         │ user.registered    │ asset.price.updated         │
│         ▼                    ▼                             │
│  ┌────────────────────── RabbitMQ ────────────────────────┐ │
│  │          Exchange: markovitz.exchange (Topic)          │ │
│  └────────────────────────┬───────────────────────────────┘ │
│                           │                                 │
│         ┌─────────────────┼──────────────────┐             │
│         ▼                 ▼                  │             │
│  ┌──────────────┐  ┌──────────────┐          │             │
│  │ notification │  │  portfolio   │ portfolio.optimized    │
│  │   service    │◀─│   service    │──────────┘             │
│  │  porta 8084  │  │  porta 8083  │                        │
│  │             │  │             │                          │
│  │ - Notific.  │  │ - Carteiras  │                         │
│  │   boas-vind │  │ - Markowitz  │                         │
│  │ - Notific.  │  │ - Pesos      │                         │
│  │   otimizaç. │  │  ótimos      │                         │
│  └─────────────┘  └─────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

## 🔬 A Matemática de Markowitz

O algoritmo implementado no `portfolio-service/MarkowitzOptimizer.java`:

### Retorno do portfólio
```
μₚ = Σ wᵢ × μᵢ
```

### Risco do portfólio (matriz diagonal)
```
σₚ = √(Σ wᵢ² × σᵢ²)
```

### Portfólio de Mínima Variância
```
wᵢ* = (1/σᵢ²) / Σⱼ(1/σⱼ²)
```

### Portfólio de Máximo Índice de Sharpe
```
wᵢ* = ((μᵢ - rf)/σᵢ²) / Σⱼ((μⱼ - rf)/σⱼ²)
```

## 🚀 Como Executar

### Pré-requisitos
- Java 17+ (ou Java 25)
- Docker Desktop instalado e rodando

### 1. Subir a infraestrutura (RabbitMQ)

```bash
# Na raiz do projeto
docker-compose up -d

# Verificar se o RabbitMQ subiu
docker ps
```

Acesse o painel do RabbitMQ: http://localhost:15672 (guest/guest)

### 2. Iniciar os microsserviços (em terminais separados)

```bash
# Terminal 1 — user-service (porta 8081)
cd user-service
.\mvnw.cmd spring-boot:run

# Terminal 2 — asset-service (porta 8082)
cd asset-service
.\mvnw.cmd spring-boot:run

# Terminal 3 — portfolio-service (porta 8083)
cd portfolio-service
.\mvnw.cmd spring-boot:run

# Terminal 4 — notification-service (porta 8084)
cd notification-service
.\mvnw.cmd spring-boot:run
```

## 🧪 Fluxo de Teste Completo

### Passo 1 — Cadastrar usuário
```http
POST http://localhost:8081/api/users/register
Content-Type: application/json

{
  "name": "João Silva",
  "email": "joao@email.com",
  "password": "senha123",
  "riskProfile": "MODERADO"
}
```
> 🔔 O `notification-service` recebe o evento e cria a notificação de boas-vindas!

### Passo 2 — Cadastrar ativos
```http
POST http://localhost:8082/api/assets
{ "ticker": "PETR4", "name": "Petrobras PN", "sector": "Energia" }

POST http://localhost:8082/api/assets
{ "ticker": "VALE3", "name": "Vale ON", "sector": "Mineração" }

POST http://localhost:8082/api/assets
{ "ticker": "WEGE3", "name": "WEG ON", "sector": "Indústria" }
```

### Passo 3 — Adicionar preços históricos (mínimo 2 por ativo)
```http
POST http://localhost:8082/api/assets/PETR4/prices
{ "price": 36.50, "priceDate": "2024-01-02" }

POST http://localhost:8082/api/assets/PETR4/prices
{ "price": 37.20, "priceDate": "2024-01-03" }

POST http://localhost:8082/api/assets/PETR4/prices
{ "price": 36.80, "priceDate": "2024-01-04" }
```
*(Repita para VALE3 e WEGE3)*

### Passo 4 — Verificar estatísticas calculadas (μ e σ)
```http
GET http://localhost:8082/api/assets/PETR4/stats
```

### Passo 5 — Criar carteira
```http
POST http://localhost:8083/api/portfolios
{
  "userId": 1,
  "name": "Minha aposentadoria",
  "tickers": ["PETR4", "VALE3", "WEGE3"],
  "optimizationGoal": "MAX_SHARPE"
}
```

### Passo 6 — Executar a otimização de Markowitz! 🎯
```http
POST http://localhost:8083/api/portfolios/1/optimize
```

> O algoritmo busca μ e σ de cada ativo no `asset-service` e calcula os pesos ótimos!

### Passo 7 — Ver notificações
```http
GET http://localhost:8084/api/notifications/user/1
```

## 📊 Endpoints Completos

| Serviço | Método | URL | Descrição |
|---------|--------|-----|-----------|
| user-service | POST | `/api/users/register` | Cadastrar usuário |
| user-service | GET | `/api/users/{id}` | Buscar usuário |
| user-service | PUT | `/api/users/{id}/risk-profile` | Atualizar perfil de risco |
| asset-service | POST | `/api/assets` | Cadastrar ativo |
| asset-service | GET | `/api/assets` | Listar ativos |
| asset-service | POST | `/api/assets/{ticker}/prices` | Adicionar preço histórico |
| asset-service | GET | `/api/assets/{ticker}/stats` | **Calcular μ e σ** |
| portfolio-service | POST | `/api/portfolios` | Criar carteira |
| portfolio-service | POST | `/api/portfolios/{id}/optimize` | **Otimização de Markowitz** |
| portfolio-service | GET | `/api/portfolios/user/{userId}` | Listar carteiras do usuário |
| notification-service | GET | `/api/notifications/user/{userId}` | Ver notificações |

## 🐰 Eventos RabbitMQ

| Publicador | Routing Key | Consumidor | Quando |
|-----------|-------------|------------|--------|
| user-service | `user.registered` | notification-service | Novo usuário cadastrado |
| asset-service | `asset.price.updated` | portfolio-service | Novo preço adicionado |
| portfolio-service | `portfolio.optimized` | notification-service | Carteira otimizada |

## 🛠️ Tecnologias

- **Java 17** + **Spring Boot 3.2**
- **Spring Data JPA** + **H2** (banco em memória)
- **Spring AMQP** + **RabbitMQ** (mensageria assíncrona)
- **Spring Web** (API REST)
- **Bean Validation** (Jakarta Validation)
- **Docker** (RabbitMQ)

## 🎓 Conceitos Estudados

- Arquitetura de Microsserviços
- Comunicação assíncrona (RabbitMQ: Exchange, Queue, Binding, Routing Key)
- Comunicação síncrona entre serviços (RestTemplate)
- JPA/Hibernate (entidades, relacionamentos @OneToMany / @ManyToOne)
- Padrões: DTO, Builder, Factory Method, Repository
- Teoria de Markowitz (μ, σ, Índice de Sharpe, Fronteira Eficiente)
