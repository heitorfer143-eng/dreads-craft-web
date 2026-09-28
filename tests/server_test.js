"use strict";
const fs=require("fs");
const os=require("os");
const path=require("path");
const http=require("http");
const {spawn}=require("child_process");

const root=path.resolve(__dirname,"..");
const dataDir=fs.mkdtempSync(path.join(os.tmpdir(),"dreads-server-test-"));
const port=18080+(process.pid%1000);
const child=spawn(process.execPath,["server.js"],{
  cwd:root,
  env:{...process.env,PORT:String(port),DREADS_DATA_DIR:dataDir},
  stdio:["ignore","pipe","pipe"]
});
let stderr="";
child.stderr.on("data",d=>{stderr+=d.toString();});

function request(rawPath){
  return new Promise((resolve,reject)=>{
    const req=http.request({host:"127.0.0.1",port,path:rawPath,method:"GET"},res=>{
      const chunks=[];
      res.on("data",d=>chunks.push(d));
      res.on("end",()=>resolve({status:res.statusCode,body:Buffer.concat(chunks).toString("utf8"),headers:res.headers}));
    });
    req.on("error",reject);
    req.end();
  });
}
async function waitForServer(){
  const deadline=Date.now()+8000;
  while(Date.now()<deadline){
    try { const r=await request("/health"); if(r.status===200) return r; } catch {}
    await new Promise(r=>setTimeout(r,80));
  }
  throw new Error("server did not start: "+stderr);
}

(async()=>{
  try {
    const health=await waitForServer();
    if(!JSON.parse(health.body).ok) throw new Error("health endpoint failed");
    const missing=await request("/definitely-missing.png");
    if(missing.status!==404) throw new Error("missing asset should be 404, got "+missing.status);
    const malformed=await request("/%ZZ");
    if(malformed.status!==400) throw new Error("malformed URL should be 400, got "+malformed.status);
    const traversal=await request("/..%2F..%2Fserver.js");
    if(traversal.status!==403) throw new Error("path traversal should be blocked, got "+traversal.status);
    console.log("PASS server health, malformed URL, missing asset and traversal handling");
  } finally {
    child.kill("SIGTERM");
    fs.rmSync(dataDir,{recursive:true,force:true});
  }
})().catch(err=>{console.error(err);child.kill("SIGTERM");fs.rmSync(dataDir,{recursive:true,force:true});process.exit(1);});
