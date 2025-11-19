async function loadNav() {
  const navContainer = document.getElementById("nav-placeholder");
  if (!navContainer) return;

  try {
    const response = await fetch("partials/nav.html");
    const html = await response.text();
    navContainer.innerHTML = html;

    // Mark active link
    const path = window.location.pathname.split("/").pop();
    const links = navContainer.querySelectorAll("nav a");
    links.forEach(link => {
      if (link.getAttribute("href") === path) {
        link.classList.add("active");
      }
    });
    
  } catch (e) {
    console.error("Navigation failed to load", e);
  }
}

loadNav();
