require('dotenv').config();

const express = require('express');
const cors = require('cors');
const Stripe = require('stripe');

const port = Number(process.env.PORT || 4242);
const secretKey = process.env.STRIPE_SECRET_KEY;

if (!secretKey || !secretKey.startsWith('sk_')) {
  console.error('Missing STRIPE_SECRET_KEY in server/.env (must start with sk_)');
  process.exit(1);
}

const stripe = new Stripe(secretKey);
const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.post('/create-payment-intent', async (req, res) => {
  try {
    const amount = Number(req.body?.amount);
    const currency = (req.body?.currency || 'ils').toLowerCase();
    const orderId = String(req.body?.orderId || '').trim();
    const description = String(req.body?.description || orderId || 'Bakery order').trim();

    if (!Number.isFinite(amount) || amount < 500) {
      return res.status(400).json({ error: 'amount must be at least 500 agorot (₪5)' });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount),
      currency,
      description,
      metadata: orderId ? { orderId } : undefined,
      automatic_payment_methods: { enabled: true },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message || 'Stripe error' });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Bakery Stripe server listening on http://0.0.0.0:${port}`);
});
