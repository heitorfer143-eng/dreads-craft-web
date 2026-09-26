"use strict";
const fs=require("fs");
const os=require("os");
const path=require("path");
const {CloudStore}=require("./cloud_store");

const dir=fs.mkdtempSync(path.join(os.tmpdir(),"dreads-cloud-test-"));
try {
  const store=new CloudStore(dir);
  const created=store.createAccount("Heitor","senha123");
  if(!created.ok) throw new Error("create account failed");
  if(store.login("Heitor","errada").ok) throw new Error("wrong password accepted");
  const login=store.login("heitor","senha123");
  if(!login.ok || !login.token) throw new Error("login failed");
  const session=store.auth(login.token);
  if(!session || session.key!=="heitor") throw new Error("session failed");
  const world={version:11,name:"Meu Reino",seed:42,day:7,creative:false,difficulty:1,saved_at:12345,cells:[[0]],surfaces:[0]};
  const saved=store.saveWorld(session.key,session.display,"reino_42",world);
  if(!saved.ok) throw new Error("save failed");
  const listed=store.listWorlds(session.key);
  if(listed.length!==1 || listed[0].name!=="Meu Reino") throw new Error("list failed");
  const restarted=new CloudStore(dir);
  const loginAfterRestart=restarted.login("Heitor","senha123");
  if(!loginAfterRestart.ok) throw new Error("account did not persist across restart");
  const loaded=restarted.loadWorld("heitor","reino_42");
  if(!loaded.ok || loaded.data.day!==7) throw new Error("world did not persist across restart");
  if(!restarted.deleteWorld("heitor","reino_42").ok || restarted.listWorlds("heitor").length!==0) throw new Error("delete failed");
  console.log("PASS cloud account persistence, cross-session login and world storage");
} finally {
  fs.rmSync(dir,{recursive:true,force:true});
}
