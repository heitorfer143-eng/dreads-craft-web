"use strict";

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const ACCOUNT_VERSION = 1;
const MAX_WORLDS_PER_ACCOUNT = 24;
const SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000;

function safeMkdir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function atomicWriteJson(file, value) {
  safeMkdir(path.dirname(file));
  const tmp = file + ".tmp-" + process.pid + "-" + Date.now();
  fs.writeFileSync(tmp, JSON.stringify(value), { encoding: "utf8", mode: 0o600 });
  fs.renameSync(tmp, file);
}

function safeWorldId(raw) {
  const id = String(raw || "").trim();
  if (!/^[a-zA-Z0-9_-]{1,80}$/.test(id)) return "";
  return id;
}

function normalizeUsername(raw) {
  const display = String(raw || "").trim();
  if (!/^[A-Za-z0-9_-]{3,20}$/.test(display)) return null;
  return { key: display.toLowerCase(), display };
}

class CloudStore {
  constructor(rootDir) {
    this.rootDir = rootDir || path.join(__dirname, "data");
    this.accountsFile = path.join(this.rootDir, "accounts.json");
    this.worldsDir = path.join(this.rootDir, "worlds");
    this.sessionSecretFile = path.join(this.rootDir, "session_secret");
    safeMkdir(this.worldsDir);
    if (!fs.existsSync(this.accountsFile)) {
      atomicWriteJson(this.accountsFile, { version: ACCOUNT_VERSION, users: {} });
    }
    if (!fs.existsSync(this.sessionSecretFile)) {
      fs.writeFileSync(this.sessionSecretFile, crypto.randomBytes(32).toString("hex"), { encoding: "utf8", mode: 0o600 });
    }
    this.sessionSecret = fs.readFileSync(this.sessionSecretFile, "utf8").trim();
  }

  _readAccounts() {
    try {
      const parsed = JSON.parse(fs.readFileSync(this.accountsFile, "utf8"));
      if (parsed && parsed.version === ACCOUNT_VERSION && parsed.users && typeof parsed.users === "object") return parsed;
    } catch {}
    return { version: ACCOUNT_VERSION, users: {} };
  }

  _writeAccounts(data) {
    data.version = ACCOUNT_VERSION;
    atomicWriteJson(this.accountsFile, data);
  }

  _hash(password, salt) {
    return crypto.scryptSync(password, salt, 64).toString("hex");
  }

  _safeEqualHex(a, b) {
    try {
      const aa = Buffer.from(String(a), "hex");
      const bb = Buffer.from(String(b), "hex");
      return aa.length === bb.length && aa.length > 0 && crypto.timingSafeEqual(aa, bb);
    } catch {
      return false;
    }
  }

  _issueSession(key, display) {
    const payload = Buffer.from(JSON.stringify({ k:key, u:display, e:Date.now()+SESSION_TTL_MS }), "utf8").toString("base64url");
    const signature = crypto.createHmac("sha256", this.sessionSecret).update(payload).digest("base64url");
    return payload + "." + signature;
  }

  createAccount(username, password) {
    const normalized = normalizeUsername(username);
    if (!normalized) return { ok: false, status: 400, message: "Usuário deve ter 3–20 caracteres: letras, números, _ ou -." };
    const pass = String(password || "");
    if (pass.length < 6 || pass.length > 72) return { ok: false, status: 400, message: "Senha precisa ter entre 6 e 72 caracteres." };
    const data = this._readAccounts();
    if (data.users[normalized.key]) return { ok: false, status: 409, message: "Esse usuário já existe." };
    const salt = crypto.randomBytes(16).toString("hex");
    data.users[normalized.key] = {
      username: normalized.display,
      salt,
      password_hash: this._hash(pass, salt),
      created_at: Date.now()
    };
    this._writeAccounts(data);
    const token = this._issueSession(normalized.key, normalized.display);
    return { ok: true, status: 201, user: normalized.display, token };
  }

  login(username, password) {
    const normalized = normalizeUsername(username);
    if (!normalized) return { ok: false, status: 401, message: "Usuário ou senha inválidos." };
    const data = this._readAccounts();
    const record = data.users[normalized.key];
    if (!record) return { ok: false, status: 401, message: "Usuário ou senha inválidos." };
    const actual = this._hash(String(password || ""), String(record.salt || ""));
    if (!this._safeEqualHex(actual, record.password_hash)) return { ok: false, status: 401, message: "Usuário ou senha inválidos." };
    const display = String(record.username || normalized.display);
    return { ok: true, status: 200, user: display, token: this._issueSession(normalized.key, display) };
  }

  auth(token) {
    try {
      const parts=String(token || "").split(".");
      if (parts.length!==2) return null;
      const expected=crypto.createHmac("sha256",this.sessionSecret).update(parts[0]).digest();
      const actual=Buffer.from(parts[1],"base64url");
      if (expected.length!==actual.length || !crypto.timingSafeEqual(expected,actual)) return null;
      const payload=JSON.parse(Buffer.from(parts[0],"base64url").toString("utf8"));
      if (!payload || Number(payload.e)<Date.now()) return null;
      const accounts=this._readAccounts();
      const record=accounts.users[String(payload.k || "")];
      if (!record) return null;
      return { key:String(payload.k), display:String(record.username || payload.u || payload.k), expires:Number(payload.e) };
    } catch {
      return null;
    }
  }

  _userWorldDir(userKey) {
    const dir = path.join(this.worldsDir, userKey);
    safeMkdir(dir);
    return dir;
  }

  _worldPath(userKey, worldId) {
    const id = safeWorldId(worldId);
    if (!id) return null;
    return path.join(this._userWorldDir(userKey), id + ".json");
  }

  _meta(id, data) {
    return {
      id,
      name: String(data.name || "Reino").slice(0, 48),
      seed: Number(data.seed || 1),
      day: Number(data.day || 1),
      clock: Number(data.clock || 0.32),
      creative: Boolean(data.creative),
      difficulty: Number(data.difficulty || 1),
      saved_at: Number(data.saved_at || Date.now() / 1000),
      version: Number(data.version || 1)
    };
  }

  listWorlds(userKey) {
    const dir = this._userWorldDir(userKey);
    const out = [];
    for (const name of fs.readdirSync(dir)) {
      if (!name.endsWith(".json")) continue;
      const id = name.slice(0, -5);
      if (!safeWorldId(id)) continue;
      try {
        const data = JSON.parse(fs.readFileSync(path.join(dir, name), "utf8"));
        if (data && typeof data === "object") out.push(this._meta(id, data));
      } catch {}
    }
    out.sort((a, b) => b.saved_at - a.saved_at);
    return out;
  }

  saveWorld(userKey, displayName, worldId, data) {
    const id = safeWorldId(worldId);
    if (!id || !data || typeof data !== "object" || Array.isArray(data)) return { ok: false, status: 400, message: "Mundo inválido." };
    const target = this._worldPath(userKey, id);
    if (!target) return { ok: false, status: 400, message: "ID de mundo inválido." };
    if (!fs.existsSync(target) && this.listWorlds(userKey).length >= MAX_WORLDS_PER_ACCOUNT) {
      return { ok: false, status: 409, message: "Limite de mundos atingido." };
    }
    const copy = JSON.parse(JSON.stringify(data));
    copy.owner = displayName;
    copy.cloud_world_id = id;
    copy.saved_at = Number(copy.saved_at || Math.floor(Date.now() / 1000));
    atomicWriteJson(target, copy);
    return { ok: true, status: 200, world: this._meta(id, copy) };
  }

  loadWorld(userKey, worldId) {
    const target = this._worldPath(userKey, worldId);
    if (!target || !fs.existsSync(target)) return { ok: false, status: 404, message: "Mundo não encontrado." };
    try {
      const data = JSON.parse(fs.readFileSync(target, "utf8"));
      return { ok: true, status: 200, id: safeWorldId(worldId), data };
    } catch {
      return { ok: false, status: 500, message: "Save corrompido no servidor." };
    }
  }

  deleteWorld(userKey, worldId) {
    const target = this._worldPath(userKey, worldId);
    if (!target) return { ok: false, status: 400, message: "ID de mundo inválido." };
    if (fs.existsSync(target)) fs.unlinkSync(target);
    return { ok: true, status: 200 };
  }
}

module.exports = { CloudStore, normalizeUsername, safeWorldId };
