const { randomUUID } = require("node:crypto");
const { initializeApp } = require("firebase-admin/app");
const { FieldValue, Timestamp, getFirestore } = require("firebase-admin/firestore");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

initializeApp();

const db = getFirestore();
const defaultBackground = "assets/themes/theme 1.jpg";
const backgrounds = {
  "assets/themes/theme 1.jpg": 0,
  "assets/themes/theme 2.jpg": 80,
  "assets/themes/theme 3.jpg": 100,
  "assets/themes/theme 4.jpg": 120,
  "assets/themes/theme 5.jpg": 150,
  "assets/themes/theme 6.jpg": 180,
  "assets/themes/Theme 7.jpg": 220,
  "assets/themes/Theme 8.jpg": 250,
};
const pets = { cat: 0 };
const missionRewards = { chat: 50, tree: 30, activity: 40, music: 20 };
const roundLengthMs = 15_000;
const roundExpiryMs = 5 * 60_000;
const dailyRewardLimit = 75;

function requireUid(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Inicia sesión para continuar.");
  return uid;
}

function stateReference(uid) {
  return db.collection("users").doc(uid).collection("game").doc("state");
}

function blankState() {
  return {
    coins: 0,
    ownedBackgrounds: [defaultBackground],
    ownedPets: [],
    activeBackground: defaultBackground,
    activePet: null,
    progress: {
      level: 1,
      xp: 0,
      xp_required: 1000,
      water: 50,
      health: 50,
      happiness: 50,
    },
    missionStatus: {},
  };
}

function clientState(state) {
  const safeState = { ...state };
  delete safeState.updatedAt;
  return safeState;
}

async function readOrCreateState(transaction, reference) {
  const snapshot = await transaction.get(reference);
  return snapshot.exists ? snapshot.data() : blankState();
}

function writeState(transaction, reference, state) {
  transaction.set(
    reference,
    { ...state, updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
}

exports.initializeGameState = onCall(async (request) => {
  const uid = requireUid(request);
  const reference = stateReference(uid);
  let state;
  await db.runTransaction(async (transaction) => {
    state = await readOrCreateState(transaction, reference);
    writeState(transaction, reference, state);
  });
  return { state: clientState(state) };
});

exports.setActiveBackground = onCall(async (request) => {
  const uid = requireUid(request);
  const assetPath = request.data?.assetPath;
  if (!Object.hasOwn(backgrounds, assetPath)) {
    throw new HttpsError("invalid-argument", "Fondo desconocido.");
  }
  const reference = stateReference(uid);
  let state;
  await db.runTransaction(async (transaction) => {
    state = await readOrCreateState(transaction, reference);
    if (!state.ownedBackgrounds.includes(assetPath)) {
      throw new HttpsError("failed-precondition", "Primero desbloquea este fondo.");
    }
    state.activeBackground = assetPath;
    writeState(transaction, reference, state);
  });
  return { state: clientState(state) };
});

exports.purchaseBackground = onCall(async (request) => {
  const uid = requireUid(request);
  const assetPath = request.data?.assetPath;
  if (!Object.hasOwn(backgrounds, assetPath) || assetPath === defaultBackground) {
    throw new HttpsError("invalid-argument", "Fondo desconocido.");
  }
  const reference = stateReference(uid);
  let result;
  await db.runTransaction(async (transaction) => {
    const state = await readOrCreateState(transaction, reference);
    if (state.ownedBackgrounds.includes(assetPath)) {
      result = { purchased: false, state };
      return;
    }
    const price = backgrounds[assetPath];
    if (state.coins < price) {
      result = { purchased: false, state };
      return;
    }
    state.coins -= price;
    state.ownedBackgrounds = [...state.ownedBackgrounds, assetPath];
    writeState(transaction, reference, state);
    result = { purchased: true, state };
  });
  return { ...result, state: clientState(result.state) };
});

exports.adoptPet = onCall(async (request) => {
  const uid = requireUid(request);
  const petId = request.data?.petId;
  if (!Object.hasOwn(pets, petId)) {
    throw new HttpsError("invalid-argument", "Mascota desconocida.");
  }
  const reference = stateReference(uid);
  let result;
  await db.runTransaction(async (transaction) => {
    const state = await readOrCreateState(transaction, reference);
    if (state.ownedPets.includes(petId)) {
      state.activePet = petId;
      writeState(transaction, reference, state);
      result = { adopted: true, state };
      return;
    }
    const price = pets[petId];
    if (state.coins < price) {
      result = { adopted: false, state };
      return;
    }
    state.coins -= price;
    state.ownedPets = [...state.ownedPets, petId];
    state.activePet = petId;
    writeState(transaction, reference, state);
    result = { adopted: true, state };
  });
  return { ...result, state: clientState(result.state) };
});

exports.setActivePet = onCall(async (request) => {
  const uid = requireUid(request);
  const petId = request.data?.petId ?? null;
  if (petId !== null && !Object.hasOwn(pets, petId)) {
    throw new HttpsError("invalid-argument", "Mascota desconocida.");
  }
  const reference = stateReference(uid);
  let state;
  await db.runTransaction(async (transaction) => {
    state = await readOrCreateState(transaction, reference);
    if (petId !== null && !state.ownedPets.includes(petId)) {
      throw new HttpsError("failed-precondition", "Primero adopta esta mascota.");
    }
    state.activePet = petId;
    writeState(transaction, reference, state);
  });
  return { state: clientState(state) };
});

exports.startMiniGame = onCall(async (request) => {
  const uid = requireUid(request);
  const roundId = randomUUID();
  await db.collection("gameSessions").doc(roundId).create({
    uid,
    createdAt: Timestamp.now(),
    expiresAt: Timestamp.fromMillis(Date.now() + roundExpiryMs),
    claimed: false,
  });
  return { roundId };
});

exports.claimMiniGameReward = onCall(async (request) => {
  const uid = requireUid(request);
  const roundId = request.data?.roundId;
  const score = request.data?.score;
  if (
    typeof roundId !== "string" ||
    !Number.isInteger(score) ||
    score < 0 ||
    score > 300
  ) {
    throw new HttpsError("invalid-argument", "La partida no es válida.");
  }
  const sessionReference = db.collection("gameSessions").doc(roundId);
  const stateReferenceForUser = stateReference(uid);
  const day = new Date().toISOString().slice(0, 10);
  const dailyReference = db
    .collection("users")
    .doc(uid)
    .collection("dailyRewards")
    .doc(day);
  let result;
  await db.runTransaction(async (transaction) => {
    const [sessionSnapshot, dailySnapshot] = await Promise.all([
      transaction.get(sessionReference),
      transaction.get(dailyReference),
    ]);
    const session = sessionSnapshot.data();
    const now = Date.now();
    const startedAt = session?.createdAt?.toMillis?.();
    if (
      !sessionSnapshot.exists ||
      session.uid !== uid ||
      session.claimed ||
      !startedAt ||
      now - startedAt < roundLengthMs ||
      now - startedAt > roundExpiryMs
    ) {
      throw new HttpsError("failed-precondition", "La partida ya venció o no terminó.");
    }

    const daily = dailySnapshot.data() ?? { claimed: 0, coins: 0 };
    const completedBars = Math.floor(score / 10);
    const desiredReward = Math.min(
      75,
      score < 5 ? 0 : score < 10 ? 8 : 15 + Math.max(0, completedBars - 1) * 5,
    );
    const remaining = Math.max(0, dailyRewardLimit - daily.coins);
    const reward = Math.min(desiredReward, remaining);
    const state = await readOrCreateState(transaction, stateReferenceForUser);
    state.coins += reward;
    transaction.update(sessionReference, {
      claimed: true,
      score,
      reward,
      claimedAt: Timestamp.now(),
    });
    transaction.set(
      dailyReference,
      {
        claimed: daily.claimed + 1,
        coins: daily.coins + reward,
      },
      { merge: true },
    );
    writeState(transaction, stateReferenceForUser, state);
    result = { reward, dailyLimitReached: remaining === 0, state };
  });
  return { ...result, state: clientState(result.state) };
});

exports.completeMission = onCall(async (request) => {
  const uid = requireUid(request);
  const missionId = request.data?.missionId;
  if (!Object.hasOwn(missionRewards, missionId)) {
    throw new HttpsError("invalid-argument", "Misión desconocida.");
  }
  const reference = stateReference(uid);
  let state;
  await db.runTransaction(async (transaction) => {
    state = await readOrCreateState(transaction, reference);
    state.missionStatus ??= {};
    if (state.missionStatus[missionId]) return;

    const progress = {
      ...blankState().progress,
      ...(state.progress ?? {}),
    };
    let xp = progress.xp + missionRewards[missionId];
    let level = progress.level;
    let xpRequired = progress.xp_required;
    while (xp >= xpRequired) {
      xp -= xpRequired;
      level += 1;
      xpRequired = 1000 + (level - 1) * 250;
    }
    progress.level = level;
    progress.xp = xp;
    progress.xp_required = xpRequired;
    if (missionId === "tree") {
      progress.water = Math.min(100, progress.water + 10);
      progress.health = Math.min(100, progress.health + 3);
    } else if (missionId === "chat") {
      progress.happiness = Math.min(100, progress.happiness + 4);
    } else if (missionId === "music") {
      progress.happiness = Math.min(100, progress.happiness + 2);
    }
    state.progress = progress;
    state.missionStatus[missionId] = true;
    writeState(transaction, reference, state);
  });
  return { state: clientState(state) };
});
