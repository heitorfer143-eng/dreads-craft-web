const http = require("http");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { WebSocketServer } = require("ws");
const { CloudStore } = require("./cloud_store");

const PORT = process.env.PORT || 8080;
const ROOT = path.join(__dirname, "public");
const DATA_ROOT = process.env.DREADS_DATA_DIR || path.join(__dirname, "data");
const cloudStore = new CloudStore(DATA_ROOT);
const rooms = new Map();
const WORLD_WIDTH_CELLS = 640;
const WORLD_HEIGHT_CELLS = 96;
const WORLD_MIN_X = 0;
const WORLD_MAX_X = WORLD_WIDTH_CELLS * 32;
const WORLD_MIN_Y = 0;
const WORLD_MAX_Y = WORLD_HEIGHT_CELLS * 32;

const mime = {
  ".html":"text/html; charset=utf-8", ".js":"application/javascript; charset=utf-8",
  ".wasm":"application/wasm", ".pck":"application/octet-stream", ".png":"image/png",
  ".svg":"image/svg+xml", ".jpg":"image/jpeg", ".jpeg":"image/jpeg",
  ".ogg":"audio/ogg", ".webp":"image/webp", ".ico":"image/x-icon",
  ".apk":"application/vnd.android.package-archive"
};

function headers(res, code=200, type="text/plain; charset=utf-8") {
  res.writeHead(code, {
    "Content-Type": type,
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Embedder-Policy": "require-corp",
    "Cross-Origin-Resource-Policy": "same-origin",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
    "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
    "Pragma":"no-cache", "Expires":"0",
    "X-Content-Type-Options":"nosniff",
    "Referrer-Policy":"no-referrer",
    "Permissions-Policy":"camera=(), microphone=(), geolocation=()",
    "X-Frame-Options":"DENY"
  });
}

function jsonHeaders(res, code=200) {
  res.writeHead(code, {
    "Content-Type":"application/json; charset=utf-8",
    "Cache-Control":"no-store",
    "X-Content-Type-Options":"nosniff",
    "Referrer-Policy":"no-referrer"
  });
}

function sendJson(res, code, value) {
  jsonHeaders(res, code);
  res.end(JSON.stringify(value));
}

function readJsonBody(req, maxBytes=10*1024*1024) {
  return new Promise((resolve, reject) => {
    let size=0, chunks=[];
    req.on("data", chunk => {
      size += chunk.length;
      if (size > maxBytes) {
        reject(Object.assign(new Error("payload too large"), { status: 413 }));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on("end", () => {
      if (!chunks.length) return resolve({});
      try { resolve(JSON.parse(Buffer.concat(chunks).toString("utf8"))); }
      catch { reject(Object.assign(new Error("invalid json"), { status: 400 })); }
    });
    req.on("error", reject);
  });
}

function bearer(req) {
  const raw=String(req.headers.authorization || "");
  return raw.startsWith("Bearer ") ? raw.slice(7).trim() : "";
}

async function handleApi(req,res,pathname) {
  try {
    if (req.method==="POST" && pathname==="/api/account/create") {
      const body=await readJsonBody(req, 64*1024);
      const result=cloudStore.createAccount(body.username,body.password);
      return sendJson(res,result.status,result);
    }
    if (req.method==="POST" && pathname==="/api/account/login") {
      const body=await readJsonBody(req, 64*1024);
      const result=cloudStore.login(body.username,body.password);
      return sendJson(res,result.status,result);
    }
    const session=cloudStore.auth(bearer(req));
    if (!session) return sendJson(res,401,{ok:false,message:"Sessão inválida. Entre novamente."});
    if (req.method==="GET" && pathname==="/api/account/me") {
      return sendJson(res,200,{ok:true,user:session.display});
    }
    if (req.method==="GET" && pathname==="/api/worlds") {
      return sendJson(res,200,{ok:true,worlds:cloudStore.listWorlds(session.key)});
    }
    const match=pathname.match(/^\/api\/worlds\/([A-Za-z0-9_-]{1,80})$/);
    if (match) {
      const worldId=match[1];
      if (req.method==="GET") {
        const result=cloudStore.loadWorld(session.key,worldId);
        return sendJson(res,result.status,result);
      }
      if (req.method==="PUT") {
        const body=await readJsonBody(req);
        const result=cloudStore.saveWorld(session.key,session.display,worldId,body.data);
        return sendJson(res,result.status,result);
      }
      if (req.method==="DELETE") {
        const result=cloudStore.deleteWorld(session.key,worldId);
        return sendJson(res,result.status,result);
      }
    }
    return sendJson(res,404,{ok:false,message:"Endpoint não encontrado."});
  } catch (err) {
    const status=Number(err && err.status) || 500;
    return sendJson(res,status,{ok:false,message:status===500?"Erro interno do servidor.":String(err.message||"Requisição inválida.")});
  }
}

const serverHttp = http.createServer((req,res)=>{
  const pathname = decodeURIComponent((req.url || "/").split("?")[0]);
  if (pathname.startsWith("/api/")) {
    handleApi(req,res,pathname);
    return;
  }
  if (pathname === "/health") {
    headers(res,200,"application/json");
    return res.end(JSON.stringify({ok:true,rooms:rooms.size}));
  }
  let reqPath = pathname;
  if (reqPath === "/") reqPath = "/index.html";
  const safe = path.normalize(reqPath).replace(/^([.][.][/\\])+/, "");
  let file = path.join(ROOT, safe);
  if (!file.startsWith(ROOT)) { headers(res,403); return res.end("forbidden"); }
  fs.stat(file,(err,st)=>{
    if (err || !st.isFile()) file = path.join(ROOT,"index.html");
    fs.readFile(file,(readErr,data)=>{
      if (readErr) { headers(res,404); return res.end("not found"); }
      headers(res,200,mime[path.extname(file).toLowerCase()] || "application/octet-stream");
      res.end(data);
    });
  });
});

const wss = new WebSocketServer({ server: serverHttp, path: "/ws", maxPayload: 16384 });

function code() {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let out="";
  do {
    out="";
    const b=crypto.randomBytes(5);
    for (let i=0;i<5;i++) out += alphabet[b[i] % alphabet.length];
  } while (rooms.has(out));
  return out;
}
function id(){ return crypto.randomBytes(6).toString("hex"); }
function send(ws,obj){ if(ws.readyState===1) ws.send(JSON.stringify(obj)); }
function broadcast(room,obj,except=null){
  const data=JSON.stringify(obj);
  for(const p of room.players.values()) if(p.ws!==except && p.ws.readyState===1) p.ws.send(data);
}
function publicPlayer(p){ return {id:p.id,name:p.name,x:p.state.x,y:p.state.y,face:p.state.face,anim:p.state.anim,zone:p.state.zone||"world"}; }
function leave(ws){
  if(!ws.room || !rooms.has(ws.room)) return;
  const room=rooms.get(ws.room);
  const p=room.players.get(ws.pid);
  if(p){
    room.players.delete(ws.pid);
    broadcast(room,{type:"leave",id:ws.pid,name:p.name});
  }
  if(room.players.size===0) rooms.delete(ws.room);
  ws.room=null; ws.pid=null;
}

wss.on("connection",(ws)=>{
  ws.room=null; ws.pid=null;

  ws.on("message",(raw)=>{
    let msg;
    try { msg=JSON.parse(raw.toString()); } catch { return; }

    if(msg.type==="create"){
      leave(ws);
      const roomCode=code();
      const seed=Number.isFinite(Number(msg.seed)) ? Math.trunc(Number(msg.seed)) : Date.now();
      const room={code:roomCode,seed,world_name:String(msg.world_name||"Reino Online").slice(0,32),players:new Map(),blocks:new Map(),drops:new Map()};
      rooms.set(roomCode,room);
      const p={id:id(),name:String(msg.name||"Jogador").slice(0,16),ws,state:{x:400,y:1000,face:1,anim:"idle",zone:"world"}};
      room.players.set(p.id,p); ws.room=roomCode; ws.pid=p.id;
      send(ws,{type:"room",room:roomCode,id:p.id,seed:room.seed,world_name:room.world_name,host:true,players:[],blocks:[],drops:[]});
      return;
    }

    if(msg.type==="join"){
      leave(ws);
      const roomCode=String(msg.room||"").trim().toUpperCase();
      const room=rooms.get(roomCode);
      if(!room){ send(ws,{type:"error",message:"Sala não encontrada."}); return; }
      const p={id:id(),name:String(msg.name||"Jogador").slice(0,16),ws,state:{x:400,y:1000,face:1,anim:"idle",zone:"world"}};
      const others=[...room.players.values()].map(publicPlayer);
      room.players.set(p.id,p); ws.room=roomCode; ws.pid=p.id;
      const blocks=[...room.blocks.entries()].map(([key,value])=>{const [x,y]=key.split(",").map(Number);return {x,y,id:value};});
      const now=Date.now();
      const drops=[...room.drops.values()].filter(d=>d.expires>now);
      send(ws,{type:"room",room:roomCode,id:p.id,seed:room.seed,world_name:room.world_name,host:false,players:others,blocks,drops});
      broadcast(room,{type:"join",player:publicPlayer(p)},ws);
      return;
    }

    if(!ws.room || !rooms.has(ws.room)) return;
    const room=rooms.get(ws.room);
    const p=room.players.get(ws.pid);
    if(!p) return;

    if(msg.type==="state"){
      const x=Number(msg.x), y=Number(msg.y);
      if(!Number.isFinite(x)||!Number.isFinite(y)) return;
      p.state={
        x:Math.max(WORLD_MIN_X+12,Math.min(WORLD_MAX_X-12,x)),
        y:Math.max(WORLD_MIN_Y+44,Math.min(WORLD_MAX_Y-4,y)),
        face:Number(msg.face)<0?-1:1,
        anim:String(msg.anim||"idle").slice(0,12),
        zone:String(msg.zone||"world").slice(0,24)
      };
      broadcast(room,{type:"state",id:p.id,name:p.name,...p.state},ws);
    } else if(msg.type==="block"){
      const x=Math.trunc(Number(msg.x)), y=Math.trunc(Number(msg.y)), block=Math.trunc(Number(msg.id));
      if(x<0||x>=WORLD_WIDTH_CELLS||y<0||y>=95||block<0||block>64) return;
      room.blocks.set(x+","+y,block);
      broadcast(room,{type:"block",x,y,id:block,by:p.id},ws);
    } else if(msg.type==="drop_spawn"){
      const itemId=Math.trunc(Number(msg.item_id)), count=Math.trunc(Number(msg.count));
      const x=Number(msg.x), y=Number(msg.y);
      if(!Number.isFinite(x)||!Number.isFinite(y)||itemId<=0||itemId>64||count<=0||count>999) return;
      if(Math.hypot(x-p.state.x,y-p.state.y)>180) return;
      const dropId=id();
      const drop={id:dropId,item_id:itemId,count,x,y,zone:p.state.zone||"world",expires:Date.now()+300000};
      room.drops.set(dropId,drop);
      broadcast(room,{type:"drop_spawn",drop});
      setTimeout(()=>{
        if(!rooms.has(room.code)) return;
        const live=rooms.get(room.code);
        if(live.drops && live.drops.has(dropId)){
          live.drops.delete(dropId);
          broadcast(live,{type:"drop_remove",drop_id:dropId});
        }
      },300500);
    } else if(msg.type==="drop_pickup"){
      const dropId=String(msg.drop_id||"");
      const drop=room.drops.get(dropId);
      if(!drop) return;
      if(drop.zone!==(p.state.zone||"world")) return;
      if(Math.hypot(drop.x-p.state.x,drop.y-p.state.y)>96) return;
      room.drops.delete(dropId);
      broadcast(room,{type:"drop_pickup",drop_id:dropId,by:p.id,item_id:drop.item_id,count:drop.count});
    } else if(msg.type==="chat"){
      const text=String(msg.text||"").trim().slice(0,120);
      if(text) broadcast(room,{type:"chat",id:p.id,name:p.name,text});
    }
  });

  ws.on("close",()=>leave(ws));
  ws.on("error",()=>leave(ws));
});

serverHttp.listen(PORT,"0.0.0.0",()=>console.log("Dreads Craft multiplayer on :"+PORT));
