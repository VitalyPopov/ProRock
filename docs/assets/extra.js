// the header title goes home, as the (hidden) logo did; the line next to it (overrides/partials/header.html) is plain text
document.addEventListener("click", function (event) {
  if (!event.target.closest(".md-header__title") || event.target.closest(".prorock-tagline")) return;
  var home = document.querySelector(".md-header__button.md-logo");
  if (home) window.location.href = home.href;
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
