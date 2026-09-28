const http = require("http");
const fs = require("fs");
const path = require("path");

const html = fs.readFileSync(path.join(__dirname, "index.html"));
const port = Number(process.env.PORT || 8080);
const MODEL = process.env.OPENAI_MODEL || "gpt-5.6";
const MAX_BODY = 1_500_000;

const send = (res, obj) => res.write(JSON.stringify(obj) + "\n");
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function safePath(p) {
  return typeof p === "string" &&
    p.length > 0 &&
    p.length < 180 &&
    !p.startsWith("/") &&
    !p.includes("..") &&
    !p.includes("\\") &&
    /^[a-zA-Z0-9_.\-/]+$/.test(p);
}

async function readJson(req) {
  let body = "";
  for await (const chunk of req) {
    body += chunk;
    if (body.length > MAX_BODY) throw new Error("Pedido grande demais.");
  }
  return JSON.parse(body || "{}");
}

function extractOutputText(payload) {
  if (typeof payload.output_text === "string") return payload.output_text;
  const parts = [];
  for (const item of payload.output || []) {
    for (const c of item.content || []) {
      if (typeof c.text === "string") parts.push(c.text);
    }
  }
  return parts.join("\n");
}

function parseProjectJson(text) {
  let s = String(text || "").trim();
  s = s.replace(/^\`\`\`(?:json)?\s*/i, "").replace(/\s*\`\`\`$/i, "");
  const a = s.indexOf("{"), b = s.lastIndexOf("}");
  if (a >= 0 && b > a) s = s.slice(a, b + 1);
  const out = JSON.parse(s);
  if (!out || typeof out !== "object") throw new Error("Resposta inválida da IA.");

  const clean = {};
  let total = 0;
  for (const [p, content] of Object.entries(out.files || {})) {
    if (!safePath(p) || typeof content !== "string") continue;
    total += content.length;
    if (content.length <= 220_000 && total <= 700_000) clean[p] = content;
  }
  return {
    message: String(out.message || "Alterações prontas."),
    mode: out.mode === "godot" ? "godot" : "web",
    files: clean,
    notes: Array.isArray(out.notes) ? out.notes.map(String).slice(0, 8) : []
  };
}

const SYSTEM = `
Você é o motor de uma IDE de programação em tempo real. Responda APENAS com JSON válido, sem markdown:
{
  "message": "explicação curta em português",
  "mode": "web" ou "godot",
  "files": {"caminho/arquivo": "conteúdo completo"},
  "notes": ["opcional"]
}

REGRAS:
- Faça o trabalho solicitado; não devolva apenas instruções.
- Para web, normalmente use index.html, styles.css e script.js.
- Para Godot 4, crie/edite project.godot, arquivos .tscn e scripts .gd necessários.
- Prefira projetos pequenos, completos e executáveis.
- Corrija o erro recebido quando houver.
- Preserve arquivos existentes que não precisem mudar.
- Pode usar pesquisa web para documentação, versões, APIs e exemplos atuais.
- Nunca coloque chaves, tokens ou segredos nos arquivos do projeto.
- Nunca gere caminhos absolutos ou contendo "..".
- Não use rede no código do preview a menos que o usuário peça explicitamente uma integração web; mesmo assim explique em notes que o preview sandbox pode bloquear rede.
- Em modo Godot, foque em Godot 4.x e cenas 2D/3D válidas.
`;

async function openAIProject(data) {
  const userPayload = {
    pedido: String(data.prompt || ""),
    tentativa: Number(data.attempt || 1),
    erro_da_execucao: String(data.error || ""),
    arquivos_atuais: data.files || {}
  };

  const body = {
    model: MODEL,
    input: [
      { role: "system", content: [{ type: "input_text", text: SYSTEM }] },
      { role: "user", content: [{ type: "input_text", text: JSON.stringify(userPayload) }] }
    ]
  };

  if (process.env.ALLOW_WEB_SEARCH !== "0") {
    body.tools = [{ type: "web_search" }];
  }

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Authorization": "Bearer " + process.env.OPENAI_API_KEY,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(90_000)
  });

  const raw = await response.text();
  if (!response.ok) {
    throw new Error("OpenAI " + response.status + ": " + raw.slice(0, 500));
  }
  const payload = JSON.parse(raw);
  return parseProjectJson(extractOutputText(payload));
}

async function streamProject(res, project) {
  for (const word of project.message.split(/(\s+)/)) {
    send(res, { type: "chat", text: word });
    await sleep(10);
  }
  if (project.mode === "godot") {
    send(res, { type: "chat", text: "\n🎮 Modo Godot 4: projeto e cena gerados." });
  }
  for (const note of project.notes) {
    send(res, { type: "chat", text: "\n• " + note });
  }
  for (const [p, content] of Object.entries(project.files)) {
    send(res, { type: "fileStart", path: p });
    for (let i = 0; i < content.length; i += 120) {
      send(res, { type: "file", text: content.slice(i, i + 120) });
      await sleep(5);
    }
    send(res, { type: "fileEnd", path: p });
  }
  send(res, { type: "mode", mode: project.mode });
}

async function demoProject(data) {
  const p = String(data.prompt || "").toLowerCase();
  if (p.includes("godot") || p.includes("3d")) {
    return {
      message: "Modo demo: gerei um projeto Godot 4 3D básico. Com a API key, a IA passa a criar qualquer projeto dinamicamente.",
      mode: "godot",
      notes: ["Godot ainda não é executado no servidor nesta versão por segurança."],
      files: {
        "project.godot": '[application]\nconfig/name="AI Code Studio 3D"\nrun/main_scene="res://main.tscn"\n[display]\nwindow/size/viewport_width=960\nwindow/size/viewport_height=540\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n',
        "main.tscn": '[gd_scene load_steps=2 format=3]\n\n[sub_resource type="BoxMesh" id="BoxMesh_demo"]\nsize = Vector3(2, 2, 2)\n\n[node name="Main" type="Node3D"]\n\n[node name="Camera3D" type="Camera3D" parent="."]\ntransform = Transform3D(1,0,0,0,1,0,0,0,1,0,2.5,6)\ncurrent = true\n\n[node name="Cube" type="MeshInstance3D" parent="."]\nmesh = SubResource("BoxMesh_demo")\n'
      }
    };
  }
  return {
    message: "Modo demo ativo. Com uma OPENAI_API_KEY no servidor, esta mesma tela passa a usar IA real e pesquisa web.",
    mode: "web",
    notes: [],
    files: {
      "index.html": '<main><h1>AI Code Studio V2</h1><p>Servidor online. Falta apenas configurar a API key.</p></main>',
      "styles.css": 'body{font-family:system-ui;padding:40px;background:#0b1020;color:#eef3ff}main{max-width:720px;margin:auto;background:#151d33;padding:30px;border-radius:20px}',
      "script.js": 'console.log("AI Code Studio V2 online")'
    }
  };
}

async function agent(req, res) {
  res.writeHead(200, {
    "content-type": "application/x-ndjson; charset=utf-8",
    "cache-control": "no-cache, no-transform",
    "x-content-type-options": "nosniff"
  });
  try {
    const data = await readJson(req);
    const project = process.env.OPENAI_API_KEY
      ? await openAIProject(data)
      : await demoProject(data);
    await streamProject(res, project);
  } catch (err) {
    send(res, { type: "chat", text: "\nErro do agente: " + (err?.message || String(err)) });
  } finally {
    res.end();
  }
}

http.createServer(async (req, res) => {
  if (req.url === "/api/health") {
    res.writeHead(200, { "content-type": "application/json", "cache-control": "no-store" });
    return res.end(JSON.stringify({
      ai: !!process.env.OPENAI_API_KEY,
      network: process.env.ALLOW_WEB_SEARCH !== "0",
      godotGeneration: true,
      godotExecution: false,
      model: process.env.OPENAI_API_KEY ? MODEL : null,
      version: "2"
    }));
  }

  if (req.url === "/api/agent" && req.method === "POST") return agent(req, res);

  if (req.url === "/" || req.url === "/index.html") {
    res.writeHead(200, {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff"
    });
    return res.end(html);
  }

  res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
  res.end("404");
}).listen(port, "0.0.0.0", () => {
  console.log("AI Code Studio V2 on " + port + " | AI=" + !!process.env.OPENAI_API_KEY);
});
