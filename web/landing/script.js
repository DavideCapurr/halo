const allowedRoles = new Set([
  "freshman",
  "msc",
  "exchange",
  "club_host",
  "founder_circle",
]);

const localKey = "halo.waitlist.preview";

function endpointFor(form) {
  return (
    form.dataset.endpoint ||
    window.HALO_WAITLIST_ENDPOINT ||
    document.querySelector("meta[name='halo-waitlist-endpoint']")?.content ||
    ""
  ).trim();
}

function payloadFrom(form) {
  const data = new FormData(form);
  const email = String(data.get("email") || "").trim().toLowerCase();
  const role = String(data.get("role") || "").trim();
  return {
    display_name: String(data.get("name") || "").trim(),
    email,
    role,
    source: String(data.get("source") || "landing_bocconi_cold_start").trim(),
  };
}

function validate(payload) {
  if (!payload.display_name) return "Add your name.";
  if (!payload.email.endsWith("@studbocconi.it")) {
    return "Use your @studbocconi.it email.";
  }
  if (!allowedRoles.has(payload.role)) return "Choose your launch role.";
  return null;
}

function setStatus(form, message, state = "") {
  const node = form.querySelector("[data-form-status]");
  if (!node) return;
  node.textContent = message;
  node.dataset.state = state;
}

function savePreview(payload) {
  const saved = JSON.parse(localStorage.getItem(localKey) || "[]");
  const next = saved.filter((row) => row.email !== payload.email);
  next.push({ ...payload, saved_at: new Date().toISOString() });
  localStorage.setItem(localKey, JSON.stringify(next));
}

async function submit(form) {
  const payload = payloadFrom(form);
  const error = validate(payload);
  if (error) {
    setStatus(form, error, "error");
    return;
  }

  const button = form.querySelector("button[type='submit']");
  button.disabled = true;
  setStatus(form, "Joining...");

  try {
    const endpoint = endpointFor(form);
    if (!endpoint) {
      savePreview(payload);
      setStatus(
        form,
        "Saved locally for preview. Configure HALO_WAITLIST_ENDPOINT for live capture.",
        "success",
      );
      form.reset();
      return;
    }

    const response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await response.json().catch(() => ({}));

    if (!response.ok || body.ok === false) {
      throw new Error(body.error || "Waitlist signup failed.");
    }

    setStatus(form, "You are on the Bocconi launch list.", "success");
    form.reset();
  } catch (err) {
    setStatus(form, err instanceof Error ? err.message : "Try again.", "error");
  } finally {
    button.disabled = false;
  }
}

for (const form of document.querySelectorAll("[data-waitlist-form]")) {
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    submit(form);
  });
}
