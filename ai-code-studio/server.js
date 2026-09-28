const http=require('http'),fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'index.html'));
const port=process.env.PORT||8080;
const send=(res,o)=>res.write(JSON.stringify(o)+'\n');
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function demo(req,res){let body='';for await(const c of req) body+=c;let data={};try{data=JSON.parse(body)}catch{};const p=(data.prompt||'').toLowerCase();res.writeHead(200,{'content-type':'application/x-ndjson; charset=utf-8','cache-control':'no-cache'});
  const say=async t=>{for(const w of t.split(/(\s+)/)){send(res,{type:'chat',text:w});await sleep(22)}};
  await say('Entendi. Vou montar isso e executar no preview. ');
  let files={};
  if(p.includes('calcul')){files={'index.html':`<main class="calc"><h1>Calculadora</h1><input id="a" type="number" placeholder="0"><select id="op"><option>+</option><option>-</option><option>×</option><option>÷</option></select><input id="b" type="number" placeholder="0"><button id="go">Calcular</button><output id="out">Resultado: —</output></main>`,'styles.css':`body{font-family:system-ui;margin:0;min-height:100vh;display:grid;place-items:center;background:linear-gradient(135deg,#18233a,#4e67d7)}.calc{width:min(360px,86vw);display:grid;gap:12px;background:white;padding:26px;border-radius:22px;box-shadow:0 22px 70px #0005}input,select,button,output{font:inherit;padding:12px;border-radius:10px;border:1px solid #d9dfeb}button{background:#315ee8;color:white;border:0;font-weight:700}output{background:#f2f5fb}`,'script.js':`go.onclick=()=>{let x=+a.value,y=+b.value,r;switch(op.value){case '+':r=x+y;break;case '-':r=x-y;break;case '×':r=x*y;break;case '÷':r=y?x/y:'Erro: divisão por zero'}out.value='Resultado: '+r}`};}
  else if(p.includes('erro')||data.error){files['script.js']='console.log("Correção aplicada com sucesso")';}
  else {files={'index.html':'<main><h1>Projeto criado</h1><p>O modo demo entende melhor “faça uma calculadora”.</p></main>','styles.css':'body{font-family:system-ui;padding:40px;background:#eef2ff;color:#172033}main{max-width:600px;margin:auto;background:white;padding:30px;border-radius:18px}','script.js':'console.log("Projeto demo executado")'};}
  for(const [p,c] of Object.entries(files)){send(res,{type:'fileStart',path:p});for(let i=0;i<c.length;i+=70){send(res,{type:'file',text:c.slice(i,i+70)});await sleep(18)}send(res,{type:'fileEnd',path:p})}res.end();
}
http.createServer(async(req,res)=>{if(req.url==='/api/health'){res.writeHead(200,{'content-type':'application/json'});return res.end(JSON.stringify({ai:!!process.env.OPENAI_API_KEY}))}if(req.url==='/api/agent'&&req.method==='POST')return demo(req,res);if(req.url==='/'||req.url==='/index.html'){res.writeHead(200,{'content-type':'text/html; charset=utf-8','cache-control':'no-store'});return res.end(html)}res.writeHead(404);res.end('404')}).listen(port,'0.0.0.0',()=>console.log('AI Code Studio on '+port));
