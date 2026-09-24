const http = require("http");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { WebSocketServer } = require("ws");

const PORT = process.env.PORT || 8080;
const ROOT = path.join(__dirname, "public");
const rooms = new Map();

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
    "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
    "Pragma":"no-cache", "Expires":"0",
    "X-Content-Type-Options":"nosniff",
    "Referrer-Policy":"no-referrer",
    "Permissions-Policy":"camera=(), microphone=(), geolocation=()",
    "X-Frame-Options":"DENY"
  });
}

const serverHttp = http.createServer((req,res)=>{
  if (req.url === "/health") {
    headers(res,200,"application/json");
    return res.end(JSON.stringify({ok:true,rooms:rooms.size}));
  }
  let reqPath = decodeURIComponent((req.url || "/").split("?")[0]);
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

const wss = new WebSocketServer({ server: serverHttp, path: "/ws" });

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
    broadcast(room,{type:"leave",id:ws.pid});
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
      const room={code:roomCode,seed,world_name:String(msg.world_name||"Reino Online").slice(0,32),players:new Map(),blocks:new Map()};
      rooms.set(roomCode,room);
      const p={id:id(),name:String(msg.name||"Jogador").slice(0,16),ws,state:{x:400,y:1000,face:1,anim:"idle",zone:"world"}};
      room.players.set(p.id,p); ws.room=roomCode; ws.pid=p.id;
      send(ws,{type:"room",room:roomCode,id:p.id,seed:room.seed,world_name:room.world_name,host:true,players:[],blocks:[]});
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
      send(ws,{type:"room",room:roomCode,id:p.id,seed:room.seed,world_name:room.world_name,host:false,players:others,blocks});
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
      p.state={x,y,face:Number(msg.face)<0?-1:1,anim:String(msg.anim||"idle").slice(0,12),zone:String(msg.zone||"world").slice(0,24)};
      broadcast(room,{type:"state",id:p.id,name:p.name,...p.state},ws);
    } else if(msg.type==="block"){
      const x=Math.trunc(Number(msg.x)), y=Math.trunc(Number(msg.y)), block=Math.trunc(Number(msg.id));
      if(x<0||x>=320||y<0||y>=95||block<0||block>64) return;
      room.blocks.set(x+","+y,block);
      broadcast(room,{type:"block",x,y,id:block,by:p.id},ws);
    } else if(msg.type==="chat"){
      const text=String(msg.text||"").trim().slice(0,120);
      if(text) broadcast(room,{type:"chat",id:p.id,name:p.name,text});
    }
  });

  ws.on("close",()=>leave(ws));
  ws.on("error",()=>leave(ws));
});

serverHttp.listen(PORT,"0.0.0.0",()=>console.log("Dreads Craft multiplayer on :"+PORT));
