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
