/**
 * Behavioural tests for ../firestore.rules.
 *
 * Run via the emulator so the real rules engine evaluates them:
 *
 *   cd firestore-tests && npm install
 *   cd .. && firebase emulators:exec --only firestore \
 *     "cd firestore-tests && npm test"
 *
 * ClockIn has no Firebase Auth — identity is a Solana wallet address and rules
 * cannot authenticate writers (see the header comment in firestore.rules). So
 * these tests assert what the rules actually promise: document shapes are
 * enforced, records cannot be deleted or rewritten after the fact, and push
 * tokens are not readable. Confidentiality of deliverables comes from the
 * Ed25519 key attestation in the client, not from these rules.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
} = require('firebase/firestore');

const WALLET = 'Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ';
const OTHER = 'A1b2C3d4E5f6G7h8J9kLMnPQRsTUVWXYZabcdefghijk';
const CONTRACT = 'ctr-mu4o1bhi';

let testEnv;
let db;

/** Writes a document bypassing rules, to set up preconditions. */
async function seed(pathSegments, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), ...pathSegments), data);
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'clockin-rules-test',
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
  // No Firebase Auth in this app: every client is unauthenticated.
  db = testEnv.unauthenticatedContext().firestore();
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe('/users/{walletAddress} — published encryption keys', () => {
  const validKey = {
    walletAddress: WALLET,
    x25519PublicKey: 'TFZGVGhpc0lzQVRlc3RYMjU1MTlQdWJsaWNLZXk9',
    x25519KeySignature: 'c2lnbmF0dXJlLWJ5dGVzLWJhc2U2NC1lbmNvZGVkLWhlcmU9',
  };

  it('is world-readable so counterparties can fetch a key', async () => {
    await seed(['users', WALLET], validKey);
    await assertSucceeds(getDoc(doc(db, 'users', WALLET)));
  });

  it('accepts a well-formed attested key', async () => {
    await assertSucceeds(setDoc(doc(db, 'users', WALLET), validKey));
  });

  it('rejects a key whose walletAddress does not match the document id', async () => {
    await assertFails(
      setDoc(doc(db, 'users', WALLET), { ...validKey, walletAddress: OTHER }),
    );
  });

  it('rejects unknown fields', async () => {
    await assertFails(
      setDoc(doc(db, 'users', WALLET), { ...validKey, isAdmin: true }),
    );
  });

  it('rejects an fcmToken smuggled into the public key document', async () => {
    await assertFails(
      setDoc(doc(db, 'users', WALLET), { ...validKey, fcmToken: 'abc' }),
    );
  });

  it('rejects an oversized key or signature', async () => {
    await assertFails(
      setDoc(doc(db, 'users', WALLET), { ...validKey, x25519PublicKey: 'A'.repeat(65) }),
    );
    await assertFails(
      setDoc(doc(db, 'users', WALLET), { ...validKey, x25519KeySignature: 'A'.repeat(129) }),
    );
  });

  it('rejects a document id that is not a base58 address', async () => {
    await assertFails(
      setDoc(doc(db, 'users', 'not-an-address'), {
        ...validKey,
        walletAddress: 'not-an-address',
      }),
    );
  });

  it('never allows deletion of a key record', async () => {
    await seed(['users', WALLET], validKey);
    await assertFails(deleteDoc(doc(db, 'users', WALLET)));
  });
});

describe('/deviceTokens/{walletAddress} — FCM push tokens', () => {
  const validToken = { walletAddress: WALLET, fcmToken: 'fake-fcm-token-value' };

  it('accepts a well-formed token write', async () => {
    await assertSucceeds(setDoc(doc(db, 'deviceTokens', WALLET), validToken));
  });

  it('is NOT readable — a readable token lets anyone push to that device', async () => {
    await seed(['deviceTokens', WALLET], validToken);
    await assertFails(getDoc(doc(db, 'deviceTokens', WALLET)));
  });

  it('rejects unknown fields', async () => {
    await assertFails(
      setDoc(doc(db, 'deviceTokens', WALLET), { ...validToken, extra: 1 }),
    );
  });

  it('never allows deletion', async () => {
    await seed(['deviceTokens', WALLET], validToken);
    await assertFails(deleteDoc(doc(db, 'deviceTokens', WALLET)));
  });
});

describe('/users/{walletAddress}/notifications — append-only inbox', () => {
  const validNotification = {
    type: 'deliverable_submitted',
    contractId: CONTRACT,
    title: 'Deliverables Ready for Review',
    body: 'Worker submitted deliverables.',
    isRead: false,
  };

  it('accepts a well-formed unread notification', async () => {
    await assertSucceeds(
      setDoc(doc(db, 'users', WALLET, 'notifications', 'n1'), validNotification),
    );
  });

  it('rejects a notification created already-read', async () => {
    await assertFails(
      setDoc(doc(db, 'users', WALLET, 'notifications', 'n1'), {
        ...validNotification,
        isRead: true,
      }),
    );
  });

  it('allows marking read, and nothing else', async () => {
    await seed(['users', WALLET, 'notifications', 'n1'], validNotification);
    await assertSucceeds(
      updateDoc(doc(db, 'users', WALLET, 'notifications', 'n1'), { isRead: true }),
    );
    await assertFails(
      updateDoc(doc(db, 'users', WALLET, 'notifications', 'n1'), { body: 'rewritten' }),
    );
  });

  it('rejects an oversized body', async () => {
    await assertFails(
      setDoc(doc(db, 'users', WALLET, 'notifications', 'n1'), {
        ...validNotification,
        body: 'x'.repeat(1001),
      }),
    );
  });

  it('never allows deletion', async () => {
    await seed(['users', WALLET, 'notifications', 'n1'], validNotification);
    await assertFails(deleteDoc(doc(db, 'users', WALLET, 'notifications', 'n1')));
  });
});

describe('/contracts/{contractId}/deliverables — encrypted envelopes', () => {
  const validSubmission = {
    contractId: CONTRACT,
    submitterAddress: WALLET,
    encryptedPayload: 'Y2lwaGVydGV4dA==',
    iv: 'aXZieXRlcw==',
    authTag: 'YXV0aFRhZw==',
    plaintextHash: 'e7d06573b4',
    status: 'submitted',
  };

  it('accepts a well-formed encrypted submission', async () => {
    await assertSucceeds(
      setDoc(doc(db, 'contracts', CONTRACT, 'deliverables', 's1'), validSubmission),
    );
  });

  it('rejects a submission whose contractId contradicts its path', async () => {
    await assertFails(
      setDoc(doc(db, 'contracts', CONTRACT, 'deliverables', 's1'), {
        ...validSubmission,
        contractId: 'ctr-different',
      }),
    );
  });

  it('rejects a non-base58 submitter address', async () => {
    await assertFails(
      setDoc(doc(db, 'contracts', CONTRACT, 'deliverables', 's1'), {
        ...validSubmission,
        submitterAddress: 'nope',
      }),
    );
  });

  it('allows the employer to flip status, but not to rewrite the ciphertext', async () => {
    await seed(['contracts', CONTRACT, 'deliverables', 's1'], validSubmission);
    await assertSucceeds(
      updateDoc(doc(db, 'contracts', CONTRACT, 'deliverables', 's1'), {
        status: 'reviewed',
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'contracts', CONTRACT, 'deliverables', 's1'), {
        encryptedPayload: 'dGFtcGVyZWQ=',
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'contracts', CONTRACT, 'deliverables', 's1'), {
        plaintextHash: 'tampered',
      }),
    );
  });

  it("never allows deletion — proof of delivery must not be erasable", async () => {
    await seed(['contracts', CONTRACT, 'deliverables', 's1'], validSubmission);
    await assertFails(deleteDoc(doc(db, 'contracts', CONTRACT, 'deliverables', 's1')));
  });
});

describe('unmatched paths', () => {
  it('are denied by the catch-all', async () => {
    await assertFails(setDoc(doc(db, 'arbitrary', 'x'), { a: 1 }));
    await assertFails(getDoc(doc(db, 'arbitrary', 'x')));
  });

  it('do not expose the contract document itself for writing', async () => {
    await assertFails(setDoc(doc(db, 'contracts', CONTRACT), { spoofed: true }));
  });
});

// Keep a stable count so a silently-empty run is obvious.
describe('suite integrity', () => {
  it('ran against the real rules file', () => {
    const rules = fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8');
    assert.ok(rules.includes('deviceTokens'), 'rules file should define deviceTokens');

    // Strip comments before scanning: the rules file documents *why* the old
    // `request.time < timestamp.date(...)` test rule was removed, so a naive
    // substring search matches that prose and fails on a correct file.
    const executable = rules
      .split('\n')
      .filter((line) => !line.trimStart().startsWith('//'))
      .join('\n');

    assert.ok(
      !executable.includes('request.time'),
      'no executable rule may gate access on request.time — an expiry clause ' +
        'silently denies all traffic once it passes',
    );
  });
});
