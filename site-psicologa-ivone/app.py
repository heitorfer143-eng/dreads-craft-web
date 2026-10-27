import os, sqlite3, secrets, hashlib
from datetime import date, datetime, timedelta
from functools import wraps
from flask import Flask, request, jsonify, render_template, redirect, url_for, session, abort
from werkzeug.security import generate_password_hash, check_password_hash

app=Flask(__name__)
app.secret_key=os.environ.get("SECRET_KEY", secrets.token_hex(32))
DB=os.environ.get("DATABASE_PATH","/data/ivone.db")
os.makedirs(os.path.dirname(DB) or ".",exist_ok=True)

def conn():
    c=sqlite3.connect(DB,timeout=20); c.row_factory=sqlite3.Row
    c.execute("PRAGMA busy_timeout=20000"); return c
def init():
    with conn() as c:
        c.executescript("""
        CREATE TABLE IF NOT EXISTS settings(k TEXT PRIMARY KEY,v TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS admins(id INTEGER PRIMARY KEY, username TEXT UNIQUE, pw TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS slots(day TEXT, time TEXT, kind TEXT, active INTEGER DEFAULT 1, PRIMARY KEY(day,time,kind));
        CREATE TABLE IF NOT EXISTS bookings(id INTEGER PRIMARY KEY, name TEXT NOT NULL, phone TEXT NOT NULL, email TEXT NOT NULL, day TEXT NOT NULL, time TEXT NOT NULL, kind TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'Solicitado', token_hash TEXT NOT NULL, created TEXT NOT NULL, UNIQUE(day,time,kind));
        CREATE TABLE IF NOT EXISTS blocks(day TEXT PRIMARY KEY, reason TEXT DEFAULT '');
        """)
        defaults={"name":"Psicóloga Ivone","tagline":"Cuidar da mente é um passo importante para transformar sua vida.","bio":"Um espaço de escuta, acolhimento e cuidado com a saúde emocional.","crp":"A preencher","education":"A preencher","phone":"A preencher","email":"A preencher","address":"A preencher","online":"1","presencial":"0"}
        for k,v in defaults.items(): c.execute("INSERT OR IGNORE INTO settings VALUES(?,?)",(k,v))
def settings():
    with conn() as c: return {r["k"]:r["v"] for r in c.execute("SELECT * FROM settings")}
def admin(fn):
    @wraps(fn)
    def w(*a,**kw):
        if not session.get("admin"): return redirect(url_for("login"))
        return fn(*a,**kw)
    return w
@app.context_processor
def ctx(): return {"s":settings()}
@app.after_request
def headers(r):
    r.headers["X-Content-Type-Options"]="nosniff"; r.headers["X-Frame-Options"]="DENY"; r.headers["Referrer-Policy"]="strict-origin-when-cross-origin"; return r
@app.get("/")
def home(): return render_template("home.html")
@app.get("/privacidade")
def privacy(): return render_template("legal.html",title="Política de privacidade",body="Usamos nome, telefone e e-mail somente para administrar solicitações de agendamento. Não envie informações clínicas pelo formulário. Antes da publicação, a responsável deve completar e revisar esta política conforme a LGPD.")
@app.get("/termos")
def terms(): return render_template("legal.html",title="Termos de uso",body="A solicitação só é confirmada quando a psicóloga atualizar o status no painel. Este site não é um serviço de emergência.")
@app.get("/api/slots")
def slots():
    day=request.args.get("day","")
    try: d=date.fromisoformat(day)
    except ValueError: return jsonify(slots=[]),400
    if d<date.today(): return jsonify(slots=[])
    with conn() as c:
        if c.execute("SELECT 1 FROM blocks WHERE day=?",(day,)).fetchone(): return jsonify(slots=[])
        rows=c.execute("""SELECT s.time,s.kind FROM slots s WHERE s.day=? AND s.active=1 AND NOT EXISTS (SELECT 1 FROM bookings b WHERE b.day=s.day AND b.time=s.time AND b.kind=s.kind AND b.status!='Cancelado') ORDER BY s.time""",(day,)).fetchall()
    return jsonify(slots=[dict(x) for x in rows])
@app.post("/api/book")
def book():
    d=request.get_json(silent=True) or {}
    name=str(d.get("name","")).strip(); phone=str(d.get("phone","")).strip(); email=str(d.get("email","")).strip()
    day=str(d.get("day","")); tm=str(d.get("time","")); kind=str(d.get("kind",""))
    if not name or len(name)>120 or not phone or len(phone)>30 or "@" not in email or len(email)>160: return jsonify(error="Confira nome, telefone e e-mail."),400
    try:
        if date.fromisoformat(day)<date.today(): raise ValueError()
        datetime.strptime(tm,"%H:%M")
    except ValueError: return jsonify(error="Data ou horário inválido."),400
    s=settings()
    if kind not in ("online","presencial") or s.get(kind,"0")!="1": return jsonify(error="Modalidade indisponível."),400
    token=secrets.token_urlsafe(32); th=hashlib.sha256(token.encode()).hexdigest()
    try:
        with conn() as c:
            c.execute("BEGIN IMMEDIATE")
            if c.execute("SELECT 1 FROM blocks WHERE day=?",(day,)).fetchone(): c.rollback(); return jsonify(error="Data bloqueada."),409
            if not c.execute("SELECT 1 FROM slots WHERE day=? AND time=? AND kind=? AND active=1",(day,tm,kind)).fetchone(): c.rollback(); return jsonify(error="Horário indisponível."),409
            cur=c.execute("INSERT INTO bookings(name,phone,email,day,time,kind,status,token_hash,created) VALUES(?,?,?,?,?,?,'Solicitado',?,?)",(name,phone,email,day,tm,kind,th,datetime.utcnow().isoformat()))
            bid=cur.lastrowid; c.commit()
    except sqlite3.IntegrityError: return jsonify(error="Esse horário acabou de ser reservado. Escolha outro."),409
    return jsonify(ok=True,id=bid,token=token,message="Solicitação registrada; aguarde a confirmação da psicóloga."),201
@app.get("/agendamento/<int:bid>")
def manage(bid):
    token=request.args.get("token",""); th=hashlib.sha256(token.encode()).hexdigest()
    with conn() as c: b=c.execute("SELECT id,day,time,status FROM bookings WHERE id=? AND token_hash=?",(bid,th)).fetchone()
    if not b: abort(404)
    return render_template("manage.html",b=b,token=token)
@app.post("/api/cancel/<int:bid>")
def cancel(bid):
    d=request.get_json(silent=True) or {}; th=hashlib.sha256(str(d.get("token","")).encode()).hexdigest()
    with conn() as c:
        cur=c.execute("UPDATE bookings SET status='Cancelado' WHERE id=? AND token_hash=? AND status!='Cancelado'",(bid,th))
        if cur.rowcount!=1: return jsonify(error="Link inválido ou solicitação já cancelada."),403
    return jsonify(ok=True,message="Solicitação cancelada.")
@app.get("/admin/login")
def login(): return render_template("login.html")
@app.post("/admin/login")
def login_post():
    with conn() as c: a=c.execute("SELECT * FROM admins WHERE username=?",(request.form.get("username",""),)).fetchone()
    if not a or not check_password_hash(a["pw"],request.form.get("password","")): return render_template("login.html",error="Usuário ou senha incorretos."),401
    session.clear(); session["admin"]=a["id"]; return redirect("/admin")
@app.post("/admin/logout")
@admin
def logout(): session.clear(); return redirect("/")
@app.get("/admin")
@admin
def dashboard():
    with conn() as c:
        bs=c.execute("SELECT * FROM bookings ORDER BY day,time LIMIT 500").fetchall()
        ss=c.execute("SELECT * FROM slots ORDER BY day,time LIMIT 500").fetchall()
        bl=c.execute("SELECT * FROM blocks ORDER BY day").fetchall()
    return render_template("admin.html",bs=bs,ss=ss,bl=bl)
@app.post("/admin/status/<int:bid>")
@admin
def status(bid):
    st=request.form.get("status","")
    if st not in ("Solicitado","Confirmado","Cancelado"): abort(400)
    with conn() as c: c.execute("UPDATE bookings SET status=? WHERE id=?",(st,bid))
    return redirect("/admin")
@app.post("/admin/slots")
@admin
def add_slots():
    day=request.form.get("day",""); start=request.form.get("start",""); end=request.form.get("end",""); kind=request.form.get("kind","online")
    try:
        if date.fromisoformat(day)<date.today(): raise ValueError()
        cur=datetime.strptime(start,"%H:%M"); stop=datetime.strptime(end,"%H:%M")
        if stop<=cur or kind not in ("online","presencial"): raise ValueError()
    except ValueError: return "Data ou intervalo inválido",400
    if settings().get(kind,"0")!="1": return "Modalidade desativada nas configurações",400
    with conn() as c:
        while cur+timedelta(minutes=50)<=stop:
            c.execute("INSERT OR IGNORE INTO slots(day,time,kind) VALUES(?,?,?)",(day,cur.strftime("%H:%M"),kind))
            cur+=timedelta(minutes=60)
    return redirect("/admin")
@app.post("/admin/block")
@admin
def block():
    day=request.form.get("day",""); reason=request.form.get("reason","")[:120]
    try:
        if date.fromisoformat(day)<date.today(): raise ValueError()
    except ValueError: return "Data inválida",400
    with conn() as c: c.execute("INSERT OR REPLACE INTO blocks VALUES(?,?)",(day,reason))
    return redirect("/admin")
@app.post("/admin/unblock/<day>")
@admin
def unblock(day):
    with conn() as c: c.execute("DELETE FROM blocks WHERE day=?",(day,))
    return redirect("/admin")
@app.post("/admin/settings")
@admin
def save():
    keys=("name","tagline","bio","crp","education","phone","email","address","online","presencial")
    with conn() as c:
        for k in keys:
            v=request.form.get(k,"").strip()[:2000]
            if k in ("online","presencial"): v="1" if v=="1" else "0"
            c.execute("INSERT INTO settings VALUES(?,?) ON CONFLICT(k) DO UPDATE SET v=excluded.v",(k,v))
    return redirect("/admin")
@app.cli.command("create-admin")
def create_admin():
    username=os.environ.get("ADMIN_USERNAME","").strip(); password=os.environ.get("ADMIN_PASSWORD","")
    if len(username)<3 or len(password)<14: raise SystemExit("Defina ADMIN_USERNAME e ADMIN_PASSWORD; senha com pelo menos 14 caracteres.")
    with conn() as c: c.execute("INSERT INTO admins(username,pw) VALUES(?,?)",(username,generate_password_hash(password)))
    print("Administrador criado.")
init()
if __name__=="__main__": app.run(host="0.0.0.0",port=int(os.environ.get("PORT","5000")))
