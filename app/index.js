const express = require('express');
const Redis = require('ioredis');
const session = require('express-session');
const RedisStore = require('connect-redis').default;

const sentinelEndpoints = (process.env.REDIS_SENTINELS || '127.0.0.1:26379')
  .split(',')
  .map(entry => {
    const [host, port] = entry.split(':');
    return { host, port: parseInt(port, 10) };
  });

const redis = new Redis({
  sentinels: sentinelEndpoints,
  name: process.env.REDIS_MASTER_NAME || 'mymaster',
  role: 'master',
});

const app = express();
const port = process.env.PORT || 3000;

app.use(session({
  store: new RedisStore({ client: redis }),
  secret: process.env.SESSION_SECRET || 'carbonfire-session-secret',
  resave: false,
  saveUninitialized: true,
  cookie: { maxAge: 24 * 60 * 60 * 1000 },
}));

app.get('/', (req, res) => {
  res.json({
    message: 'CarbonFire Redis demo',
    endpoints: ['/health', '/cache', '/leaderboard', '/session', '/rate'],
  });
});

app.get('/health', (req, res) => {
  res.json({ ok: true });
});

app.get('/cache', async (req, res) => {
  const key = 'carbonfire:cache:hello';
  const cached = await redis.get(key);
  if (cached) {
    return res.json({ hit: true, value: cached });
  }
  const value = `cached-value-${Date.now()}`;
  await redis.set(key, value, 'EX', 20);
  res.json({ hit: false, value });
});

app.get('/leaderboard', async (req, res) => {
  const member = req.query.user || 'user1';
  const score = parseInt(req.query.score || '1', 10);
  await redis.zincrby('carbonfire:leaderboard', score, member);
  const top10 = await redis.zrevrange('carbonfire:leaderboard', 0, 9, 'WITHSCORES');
  const formatted = [];
  for (let i = 0; i < top10.length; i += 2) {
    formatted.push({ user: top10[i], score: parseInt(top10[i + 1], 10) });
  }
  res.json({ leaderboard: formatted });
});

app.get('/session', (req, res) => {
  req.session.views = (req.session.views || 0) + 1;
  res.json({ sessionId: req.sessionID, views: req.session.views });
});

app.get('/rate', async (req, res) => {
  const ip = req.ip;
  const key = `carbonfire:rate:${ip}`;
  const hits = await redis.incr(key);
  if (hits === 1) {
    await redis.expire(key, 60);
  }
  const allowed = hits <= 10;
  if (!allowed) {
    return res.status(429).json({ ip, hits, allowed, limit: 10 });
  }
  res.json({ ip, hits, allowed, limit: 10 });
});

app.listen(port, () => {
  console.log(`CarbonFire app listening on port ${port}`);
  console.log(`Redis sentinels: ${JSON.stringify(sentinelEndpoints)}`);
});
