const state = {
  screen: "dashboard",
};

const data = {
  property: {
    name: "Sítio Boa Esperança",
    owner: "Marina Alves",
    city: "Unaí, MG",
    crop: "Tomate e milho safrinha",
    area: "18,4 ha",
    goal: "Reduzir perdas por umidade irregular e praga",
    nextWindow: "Janela ideal de manejo: hoje, 16h-18h",
  },
  summary: {
    urgent: 2,
    attention: 4,
    ok: 9,
    productiveArea: "16,9 ha",
    estimatedSavings: "R$ 1.280",
    score: 84,
  },
  alerts: [
    {
      level: "urgent",
      title: "Irrigar o Talhão Norte 2 hoje",
      detail: "Umidade caiu para 18%. A cultura pode perder vigor nas próximas 24 horas.",
    },
    {
      level: "attention",
      title: "Revisar risco de pinta-preta no Leste",
      detail: "Temperatura alta com chuva recente elevou o risco para médio.",
    },
    {
      level: "ok",
      title: "Talhão Oeste está estável",
      detail: "Solo, chuva e temperatura seguem dentro da faixa esperada.",
    },
  ],
  recommendations: [
    {
      title: "Aplicar irrigação leve e fracionada",
      where: "Talhão Norte 2",
      priority: "Alta",
      reason: "Solo seco na camada de 20 cm e previsão sem chuva até amanhã.",
    },
    {
      title: "Inspecionar folhas baixas e bordas",
      where: "Talhão Leste",
      priority: "Média",
      reason: "Sensores e histórico apontam início de ambiente favorável a fungo.",
    },
    {
      title: "Ajustar adubação de cobertura",
      where: "Talhão Sul",
      priority: "Média",
      reason: "Plantas com crescimento desigual após chuva forte na semana passada.",
    },
  ],
  environment: [
    { label: "Umidade do solo", value: "18%", trend: "Baixa no Norte 2" },
    { label: "Temperatura", value: "31,4°C", trend: "Acima da média da semana" },
    { label: "Chuva acumulada", value: "14 mm", trend: "Últimos 3 dias" },
    { label: "Risco de praga/doença", value: "Médio", trend: "Monitorar hoje" },
  ],
  fields: [
    { name: "Norte 2", crop: "Tomate", area: "4,2 ha", status: "urgent", note: "Umidade crítica" },
    { name: "Sul", crop: "Milho", area: "5,6 ha", status: "attention", note: "Adubação em revisão" },
    { name: "Leste", crop: "Tomate", area: "3,8 ha", status: "attention", note: "Risco fitossanitário" },
    { name: "Oeste", crop: "Milho", area: "4,8 ha", status: "ok", note: "Condição estável" },
  ],
  history: [
    {
      date: "Hoje",
      title: "Alerta de irrigação emitido",
      detail: "Norte 2 entrou em prioridade alta por queda contínua de umidade.",
    },
    {
      date: "09 mai",
      title: "Pulverização registrada",
      detail: "Tratamento preventivo concluído no Talhão Leste.",
    },
    {
      date: "07 mai",
      title: "Chuva forte detectada",
      detail: "Recomendação automática de revisar drenagem no Talhão Sul.",
    },
  ],
  onboarding: {
    producer: "Marina Alves",
    crop: "Tomate",
    area: "18,4",
    goal: "Reduzir perdas e organizar irrigação",
  },
};

const screens = [
  { id: "dashboard", label: "Dashboard", meta: "Resumo da propriedade" },
  { id: "alerts", label: "Alertas", meta: "O que precisa de atenção" },
  { id: "recommendations", label: "Recomendações", meta: "Ação prática" },
  { id: "areas", label: "Áreas", meta: "Talhões e mapa" },
  { id: "history", label: "Histórico", meta: "Decisões realizadas" },
  { id: "property", label: "Propriedade", meta: "Perfil e cadastro" },
];

const navEl = document.querySelector("#nav");
const heroEl = document.querySelector("#hero");
const screenEl = document.querySelector("#screen");

function badgeClass(level) {
  return level === "urgent" ? "urgent" : level === "attention" ? "attention" : "ok";
}

function badgeLabel(level) {
  return level === "urgent" ? "Ação urgente" : level === "attention" ? "Atenção" : "Tudo certo";
}

function icon(name) {
  const icons = {
    dashboard:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 13h7V4H4zm9 7h7v-9h-7zM4 20h7v-5H4zm9-9h7V4h-7z" fill="currentColor"/></svg>',
    alerts:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3 2 21h20L12 3Zm1 13h-2v-5h2zm0 3h-2v-2h2z" fill="currentColor"/></svg>',
    recommendations:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2 4 6v6c0 5 3.4 9.7 8 11 4.6-1.3 8-6 8-11V6l-8-4Zm-1.1 14.4-3.2-3.2 1.4-1.4 1.8 1.8 4-4 1.4 1.4-5.4 5.4Z" fill="currentColor"/></svg>',
    areas:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 5 9 3 3 5v14l6-2 6 2 6-2V3l-6 2Zm0 2.1 4-1.3v9.7l-4 1.3Zm-2 .1v9.7l-4-1.3V5.9Zm-8-.1 4-1.3v9.7l-4 1.3Z" fill="currentColor"/></svg>',
    history:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M13 3a9 9 0 1 0 8.9 10.5h-2a7 7 0 1 1-2-6.1L15 10h7V3l-2.6 2.6A8.9 8.9 0 0 0 13 3Zm-1 5h2v5l4 2-1 1.7-5-2.7V8Z" fill="currentColor"/></svg>',
    property:
      '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3 3 8v13h18V8l-9-5Zm0 2.3 6 3.3V19h-3v-5H9v5H6V8.6l6-3.3Z" fill="currentColor"/></svg>',
  };

  return icons[name] || "";
}

function renderNav() {
  navEl.innerHTML = screens
    .map(
      (screen) => `
        <button class="nav-item ${state.screen === screen.id ? "is-active" : ""}" data-screen="${screen.id}" type="button">
          <span style="display:flex;align-items:center;gap:12px;">
            <span style="width:20px;height:20px;display:inline-grid;place-items:center;">${icon(screen.id)}</span>
            <span>${screen.label}</span>
          </span>
          <span class="nav-meta">${screen.meta}</span>
        </button>
      `,
    )
    .join("");
}

function renderHero() {
  heroEl.innerHTML = `
    <section class="hero-panel">
      <div class="hero-copy">
        <p class="eyebrow">Decisão assistida para pequenos produtores</p>
        <h2>${data.property.name} trabalha melhor quando a prioridade fica clara.</h2>
        <p>
          O IZES transforma sensores, clima e histórico da propriedade em decisões simples:
          o que fazer, onde agir e qual risco evitar hoje.
        </p>
        <div class="hero-actions">
          <button class="primary-button" type="button" data-screen-jump="recommendations">Ver ações de hoje</button>
          <button class="ghost-button" type="button" data-screen-jump="property">Atualizar cadastro</button>
        </div>
      </div>
      <div class="hero-highlight">
        <div>
          <p class="mini-label">Janela recomendada</p>
          <strong style="font-size:1.8rem;letter-spacing:-0.04em;">${data.property.nextWindow}</strong>
        </div>
        <div class="hero-stat">
          <span>Índice de prontidão</span>
          <strong>${data.summary.score}</strong>
        </div>
        <div class="hero-stat">
          <span>Economia estimada</span>
          <strong>${data.summary.estimatedSavings}</strong>
        </div>
      </div>
    </section>
  `;
}

function renderDashboard() {
  return `
    <div class="screen-grid">
      <header class="screen-header">
        <p class="section-label">Resumo da propriedade</p>
        <h2>Visão rápida para decidir sem perder tempo no campo.</h2>
        <p>${data.property.crop} em ${data.property.area}, com foco em ${data.property.goal.toLowerCase()}.</p>
      </header>

      <section class="metrics-grid">
        <article class="surface-card metric-card action">
          <p class="mini-label">Ação urgente</p>
          <strong>${data.summary.urgent}</strong>
          <p>Demandas que pedem resposta ainda hoje.</p>
        </article>
        <article class="surface-card metric-card attention">
          <p class="mini-label">Atenção</p>
          <strong>${data.summary.attention}</strong>
          <p>Pontos para acompanhar antes que virem perda.</p>
        </article>
        <article class="surface-card metric-card ok">
          <p class="mini-label">Tudo certo</p>
          <strong>${data.summary.ok}</strong>
          <p>Áreas estáveis e dentro do esperado.</p>
        </article>
        <article class="surface-card metric-card">
          <p class="mini-label">Área produtiva</p>
          <strong>${data.summary.productiveArea}</strong>
          <p>Leitura consolidada com base no ciclo atual.</p>
        </article>
      </section>

      <section class="split-grid">
        <article class="surface-card">
          <p class="section-label">Alertas inteligentes</p>
          <div class="alert-stack">
            ${data.alerts
              .map(
                (alert) => `
                  <div class="alert-row">
                    <div>
                      <p><strong>${alert.title}</strong></p>
                      <p>${alert.detail}</p>
                    </div>
                    <span class="status-pill ${badgeClass(alert.level)}">${badgeLabel(alert.level)}</span>
                  </div>
                `,
              )
              .join("")}
          </div>
        </article>

        <article class="surface-card">
          <p class="section-label">Monitoramento ambiental</p>
          <div class="tile-list">
            ${data.environment
              .map(
                (item) => `
                  <div class="tile">
                    <div class="tile-header">
                      <div>
                        <p class="mini-label">${item.label}</p>
                        <strong style="font-size:1.6rem;letter-spacing:-0.04em;">${item.value}</strong>
                      </div>
                      <span class="chip">${item.trend}</span>
                    </div>
                  </div>
                `,
              )
              .join("")}
          </div>
        </article>
      </section>
    </div>
  `;
}

function renderRecommendations() {
  return `
    <div class="screen-grid">
      <header class="screen-header">
        <p class="section-label">Recomendações práticas</p>
        <h2>Orientações diretas para transformar leitura em ação.</h2>
        <p>Cada recomendação indica o que fazer, onde agir, prioridade e motivo.</p>
      </header>
      <section class="tile-list">
        ${data.recommendations
          .map(
            (item) => `
              <article class="surface-card">
                <div class="tile-header">
                  <div>
                    <p class="mini-label">O que fazer</p>
                    <h3 style="margin:0 0 8px;">${item.title}</h3>
                    <p>${item.reason}</p>
                  </div>
                  <span class="status-pill ${item.priority === "Alta" ? "urgent" : "attention"}">${item.priority}</span>
                </div>
                <div class="tile-list" style="margin-top:16px;">
                  <div class="tile">
                    <p class="mini-label">Onde agir</p>
                    <p><strong>${item.where}</strong></p>
                  </div>
                  <div class="tile">
                    <p class="mini-label">Motivo</p>
                    <p>${item.reason}</p>
                  </div>
                </div>
              </article>
            `,
          )
          .join("")}
      </section>
    </div>
  `;
}

function renderAlerts() {
  return `
    <div class="screen-grid">
      <header class="screen-header">
        <p class="section-label">Alertas</p>
        <h2>Três níveis para facilitar a decisão no dia.</h2>
        <p>Sem excesso de dados: só o que pede ação urgente, atenção ou pode seguir como está.</p>
      </header>
      <section class="history-grid">
        ${data.alerts
          .map(
            (alert) => `
              <article class="surface-card">
                <span class="status-pill ${badgeClass(alert.level)}">${badgeLabel(alert.level)}</span>
                <h3>${alert.title}</h3>
                <p>${alert.detail}</p>
              </article>
            `,
          )
          .join("")}
      </section>
    </div>
  `;
}

function renderAreas() {
  return `
    <div class="screen-grid">
      <header class="screen-header">
        <p class="section-label">Talhões e áreas</p>
        <h2>Mapa simples da propriedade com contexto de manejo.</h2>
        <p>Leitura visual rápida para identificar onde agir primeiro.</p>
      </header>
      <section class="split-grid">
        <article class="surface-card">
          <div class="field-map">
            <div class="field-visual">
              <div class="field-block north">
                <strong>Norte 2</strong>
                <span>Umidade crítica</span>
              </div>
              <div class="field-block south">
                <strong>Sul</strong>
                <span>Adubação em revisão</span>
              </div>
              <div class="field-block east">
                <strong>Leste</strong>
                <span>Risco fitossanitário</span>
              </div>
              <div class="field-block west">
                <strong>Oeste</strong>
                <span>Condição estável</span>
              </div>
            </div>
            <div class="legend">
              <p class="section-label">Legenda</p>
              <div class="legend-item"><span class="legend-swatch" style="background:#31523b;"></span><span>Norte 2</span></div>
              <div class="legend-item"><span class="legend-swatch" style="background:#7c583f;"></span><span>Sul</span></div>
              <div class="legend-item"><span class="legend-swatch" style="background:#48613c;"></span><span>Leste</span></div>
              <div class="legend-item"><span class="legend-swatch" style="background:#5f6c4b;"></span><span>Oeste</span></div>
            </div>
          </div>
        </article>
        <article class="surface-card">
          <p class="section-label">Situação por talhão</p>
          <div class="field-grid">
            ${data.fields
              .map(
                (field) => `
                  <div class="field-row">
                    <div>
                      <p><strong>${field.name}</strong> <span class="zone-pill">${field.crop}</span></p>
                      <p>${field.area} · ${field.note}</p>
                    </div>
                    <span class="status-pill ${badgeClass(field.status)}">${badgeLabel(field.status)}</span>
                  </div>
                `,
              )
              .join("")}
          </div>
        </article>
      </section>
    </div>
  `;
}

function renderHistory() {
  return `
    <div class="screen-grid">
      <header class="screen-header">
        <p class="section-label">Histórico</p>
        <h2>Rastro claro das decisões e ações realizadas.</h2>
        <p>Ajuda o produtor, técnico e cooperativa a revisar o que já foi feito.</p>
      </header>
      <section class="history-grid">
        <article class="surface-card">
          <p class="section-label">Linha do tempo</p>
          <div class="timeline-list">
            ${data.history
              .map(
                (item) => `
                  <div class="timeline-item">
                    <span class="timeline-date">${item.date}</span>
                    <div>
                      <p><strong>${item.title}</strong></p>
                      <p>${item.detail}</p>
                    </div>
                  </div>
                `,
              )
              .join("")}
          </div>
        </article>
        <article class="surface-card">
          <p class="section-label">Impacto recente</p>
          <div class="tile-list">
            <div class="tile">
              <p class="mini-label">Perda evitada</p>
              <p><strong>3,1%</strong> em estresse hídrico no Norte 2.</p>
            </div>
            <div class="tile">
              <p class="mini-label">Rotina organizada</p>
              <p>4 ações registradas sem depender de planilha separada.</p>
            </div>
            <div class="tile">
              <p class="mini-label">Conversa com técnico</p>
              <p>Histórico pronto para revisão na próxima visita.</p>
            </div>
          </div>
        </article>
      </section>
    </div>
  `;
}

function renderProperty() {
  return `
    <div class="screen-grid">
      <header class="screen-header">
        <p class="section-label">Perfil da propriedade</p>
        <h2>Cadastro simples para manter a recomendação útil no dia a dia.</h2>
        <p>Interface pensada para pequeno produtor, com poucos campos e linguagem direta.</p>
      </header>
      <section class="profile-grid">
        <article class="surface-card profile-card">
          <div>
            <p class="section-label">Resumo</p>
            <h3 style="margin:0 0 10px;">${data.property.name}</h3>
            <p>${data.property.owner} · ${data.property.city}</p>
          </div>
          <div class="profile-stats">
            <div class="profile-stat">
              <strong>${data.property.area}</strong>
              <p>Área cadastrada</p>
            </div>
            <div class="profile-stat">
              <strong>${data.property.crop}</strong>
              <p>Cultura principal</p>
            </div>
            <div class="profile-stat">
              <strong>${data.summary.score}</strong>
              <p>Índice de prontidão</p>
            </div>
            <div class="profile-stat">
              <strong>Pequeno porte</strong>
              <p>Perfil atendido</p>
            </div>
          </div>
        </article>

        <article class="onboarding-card">
          <p class="section-label">Onboarding</p>
          <form class="onboarding-grid" id="onboarding-form">
            <div class="field-group">
              <label for="producer">Produtor</label>
              <input id="producer" name="producer" value="${data.onboarding.producer}" />
            </div>
            <div class="field-group">
              <label for="crop">Cultura</label>
              <select id="crop" name="crop">
                <option ${data.onboarding.crop === "Tomate" ? "selected" : ""}>Tomate</option>
                <option ${data.onboarding.crop === "Milho" ? "selected" : ""}>Milho</option>
                <option>Feijão</option>
                <option>Mandioca</option>
              </select>
            </div>
            <div class="field-group">
              <label for="area">Área total (ha)</label>
              <input id="area" name="area" value="${data.onboarding.area}" />
            </div>
            <div class="field-group">
              <label for="goal">Objetivo</label>
              <input id="goal" name="goal" value="${data.onboarding.goal}" />
            </div>
          </form>
          <p class="form-note">Cadastro rápido para começar a receber recomendações mais úteis.</p>
        </article>
      </section>
    </div>
  `;
}

function renderScreen() {
  const map = {
    dashboard: renderDashboard,
    alerts: renderAlerts,
    recommendations: renderRecommendations,
    areas: renderAreas,
    history: renderHistory,
    property: renderProperty,
  };

  screenEl.innerHTML = map[state.screen]();
}

function renderApp() {
  renderNav();
  renderHero();
  renderScreen();
}

document.addEventListener("click", (event) => {
  const navButton = event.target.closest("[data-screen]");
  const jumpButton = event.target.closest("[data-screen-jump]");

  if (navButton) {
    state.screen = navButton.dataset.screen;
    renderApp();
  }

  if (jumpButton) {
    state.screen = jumpButton.dataset.screenJump;
    renderApp();
  }
});

document.addEventListener("change", (event) => {
  const form = event.target.closest("#onboarding-form");
  if (!form) return;

  const formData = new FormData(form);
  data.onboarding = Object.fromEntries(formData.entries());
  data.property.owner = data.onboarding.producer;
  data.property.crop = data.onboarding.crop;
  data.property.area = `${data.onboarding.area} ha`;
  data.property.goal = data.onboarding.goal;
  renderApp();
});

renderApp();
