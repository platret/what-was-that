const examples = [
  { title: "Perfect Days", person: "Mia", category: "film", symbol: "◉" },
  {
    title: "The Grand Budapest Hotel",
    person: "Leo",
    category: "film",
    symbol: "◉",
  },
  {
    title: "That little ramen place",
    person: "Noah",
    category: "food",
    symbol: "♨",
  },
  {
    title: "Sunday at the bakery",
    person: "Mia",
    category: "food",
    symbol: "♨",
  },
  {
    title: "A morning by the lake",
    person: "Mia",
    category: "place",
    symbol: "⌁",
  },
  {
    title: "The long way home",
    person: "Noah",
    category: "place",
    symbol: "⌁",
  },
  { title: "Firewatch", person: "Leo", category: "game", symbol: "⌘" },
];
let category = "all";
let previous = "";
const button = document.querySelector("#pick-button");
const card = document.querySelector(".demo-card");
document.querySelectorAll("[data-category]").forEach((tab) => {
  tab.addEventListener("click", () => {
    category = tab.dataset.category;
    document.querySelectorAll("[data-category]").forEach((other) => {
      const active = other === tab;
      other.classList.toggle("active", active);
      other.setAttribute("aria-pressed", String(active));
    });
  });
});
button?.addEventListener("click", async () => {
  button.disabled = true;
  card.classList.add("choosing");
  const reducedMotion = window.matchMedia(
    "(prefers-reduced-motion: reduce)",
  ).matches;
  await new Promise((resolve) => setTimeout(resolve, reducedMotion ? 0 : 280));
  let pool = examples.filter(
    (item) => category === "all" || item.category === category,
  );
  if (pool.length > 1) pool = pool.filter((item) => item.title !== previous);
  const item = pool[Math.floor(Math.random() * pool.length)];
  previous = item.title;
  document.querySelector("#demo-title").textContent = item.title;
  document.querySelector("#demo-from").textContent =
    `From ${item.person}. “Trust me on this one.”`;
  document.querySelector("#demo-symbol").textContent = item.symbol;
  document.querySelector("#demo-kind").textContent = {
    film: "SOMETHING TO WATCH",
    food: "SOMETHING TO SAVOUR",
    place: "SOMEWHERE TO GO",
    game: "SOMETHING TO PLAY",
  }[item.category];
  button.innerHTML = "Another good idea <span>⤨</span>";
  card.classList.remove("choosing");
  button.disabled = false;
});
