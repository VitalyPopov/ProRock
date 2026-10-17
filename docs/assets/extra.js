// the header title goes home, as the (hidden) logo did
document.addEventListener("click", function (event) {
  if (!event.target.closest(".md-header__title")) return;
  var home = document.querySelector(".md-header__button.md-logo");
  if (home) window.location.href = home.href;
});

// the positioning line next to the site name; the theme replaces the whole topic with the page title on scrolling
document.addEventListener("DOMContentLoaded", function () {
  var topic = document.querySelector(".md-header__title .md-header__topic:first-child");
  if (!topic) return;
  var tagline = document.createElement("span");
  tagline.className = "prorock-tagline";
  tagline.textContent = "When the schema changes, regenerate, don't re-patch.";
  topic.appendChild(tagline);
});

// a screenshot linked to itself opens enlarged over the page; a click anywhere or Esc closes it
document.addEventListener("click", function (event) {
  var link = event.target.closest(".md-typeset a");
  if (!link || !link.querySelector("img") || !/\.(png|jpe?g|webp)$/i.test(link.getAttribute("href"))) return;
  event.preventDefault();
  var overlay = document.createElement("div");
  overlay.className = "prorock-lightbox";
  var image = document.createElement("img");
  image.src = link.href;
  image.alt = link.querySelector("img").alt;
  overlay.appendChild(image);
  function close() {
    overlay.remove();
    document.removeEventListener("keydown", onKey);
  }
  function onKey(e) {
    if (e.key === "Escape") close();
  }
  overlay.addEventListener("click", close);
  document.addEventListener("keydown", onKey);
  document.body.appendChild(overlay);
});
