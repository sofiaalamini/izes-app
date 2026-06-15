# IZES

![Flutter](https://img.shields.io/badge/Flutter-Mobile-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-API-3776AB?logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1?logo=postgresql&logoColor=white)
![Railway](https://img.shields.io/badge/Railway-Deploy-0B0D0E?logo=railway&logoColor=white)

Plataforma inteligente de monitoramento agricola que integra sensores, clima e inteligencia artificial para auxiliar produtores rurais na tomada de decisao.

## Visao geral

O repositorio reune:

- `izesapp`: aplicativo Flutter
- `IZES-AGRO/agrisoil-backend`: API FastAPI

O foco do projeto e transformar dados do campo em acoes praticas, com leitura de sensores, alertas, clima e apoio por IA em uma experiencia acessivel.

## Funcionalidades

- 📊 Dashboard de monitoramento
- 🚨 Alertas agricolas
- 🌦️ Monitoramento climatico
- 📡 Integracao com sensores
- 🤖 Assistente IA
- 🖼️ Upload e analise de imagens
- ⏱️ Monitoramento em tempo real

## Tecnologias

### Frontend

- Flutter
- Dart

### Backend

- FastAPI
- Python
- Uvicorn
- SQLAlchemy

### Banco de dados

- PostgreSQL

### Infraestrutura

- Railway
- Docker

## Estrutura do projeto

```text
.
|-- lib/
|   |-- app/
|   |-- core/
|   |   |-- config/
|   |   |-- data/
|   |   |-- models/
|   |   |-- services/
|   |   |-- theme/
|   |   `-- utils/
|   |-- features/
|   |   |-- ai_assistant/
|   |   |-- alerts/
|   |   |-- auth/
|   |   |-- dashboard/
|   |   |-- fields/
|   |   |-- history/
|   |   |-- home/
|   |   |-- monitoring/
|   |   |-- onboarding/
|   |   |-- profile/
|   |   `-- recommendations/
|   |-- shared/
|   |   `-- widgets/
|   `-- main.dart
|-- IZES-AGRO/
|   |-- agrisoil-backend/
|   |   |-- app/
|   |   |-- monitoring/
|   |   |-- scripts/
|   |   |-- tests/
|   |   |-- requirements.txt
|   |   `-- run_server.py
|   |-- Dockerfile
|   |-- Procfile
|   `-- railway.json
|-- .env.example
|-- pubspec.yaml
`-- README.md
```

## Como executar o projeto

### Pre-requisitos

- Flutter SDK instalado
- Dart SDK compativel com o projeto
- Python 3.10+ recomendado
- PostgreSQL disponivel para o backend

### Frontend

Na raiz do projeto:

```bash
flutter pub get
flutter run
```

Se precisar configurar variaveis locais do app, crie um `.env` na raiz com base em `.env.example`.

### Backend

Entre no backend real do projeto:

```bash
cd IZES-AGRO/agrisoil-backend
python -m venv .venv
```

Ativacao no Windows:

```bash
.venv\Scripts\activate
```

Instalacao e execucao:

```bash
pip install -r requirements.txt
python run_server.py
```

Documentacao da API:

```text
http://127.0.0.1:8000/docs
```

## Variaveis de ambiente

### Frontend

Arquivo base disponivel em `.env.example`:

```env
API_BASE_URL=
API_CLIENT_ID=
API_APP_TOKEN=
API_AUTH_EMAIL=
API_AUTH_PASSWORD=
```

### Backend

Exemplos de variaveis usadas pelo backend:

```env
DATABASE_URL=
OPENWEATHERMAP_API_KEY=
SECRET_KEY=
SENSOR_API_KEY=
APP_INTERNAL_TOKEN=
OPENAI_API_KEY=
APP_ENV=development
```

## Capturas de tela

Espaco reservado para screenshots do app:

```md
![Dashboard](./docs/screenshots/dashboard.png)
![Clima](./docs/screenshots/clima.png)
![Assistente IA](./docs/screenshots/ia.png)
```

## Equipe

Equipe Calangos

- Sofia Alamini
- Pietro
- Fernando

## Objetivo do projeto

Transformar dados do campo em decisoes rapidas e acessiveis para pequenos produtores rurais.

## Melhorias futuras

- 🔔 Push notifications
- 🕓 Historico de sensores
- 📄 Relatorios inteligentes
- 🧠 Mais analises por IA

## Licenca

Definir licenca do projeto.
