(() => {
  const endpoint = window.GBLatestPostsGrid?.graphqlEndpoint || "/graphql";

  function firstInt(v, dflt) {
    const n = parseInt(v, 10);
    return Number.isFinite(n) ? n : dflt;
  }

  async function fetchPosts(first) {
    const query = `
      query LPG($first:Int!){
        posts(first:$first){
          nodes{
            databaseId
            title
            date
            uri
            featuredImage { node { sourceUrl } }
            excerpt
          }
        }
      }`;
    const res = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query, variables: { first } }),
    });
    const json = await res.json();
    if (!json?.data?.posts?.nodes) throw new Error("No posts from GraphQL");
    return json.data.posts.nodes;
  }

  function renderCards(root, posts) {
    root.innerHTML = `
      <div class="lpg-grid">
        ${posts
          .map(
            (p) => `
          <article class="lpg-card">
            ${
              p.featuredImage?.node?.sourceUrl
                ? `<a class="lpg-img" href="${p.uri}"><img src="${p.featuredImage.node.sourceUrl}" alt=""></a>`
                : ""
            }
            <div class="lpg-meta">
              <h3 class="lpg-title"><a href="${p.uri}">${p.title}</a></h3>
              <div class="lpg-date">${new Date(p.date).toLocaleDateString()}</div>
            </div>
          </article>`
          )
          .join("")}
      </div>`;
  }

  function initOne(blockEl) {
    // prefer an inner .lpg-root if present, otherwise render into the block wrapper
    const root =
      blockEl.querySelector(".lpg-root") ||
      blockEl.querySelector(".lpg-mount") ||
      blockEl;

    // read attributes if present; otherwise fall back to 6
    const want = firstInt(
      root.dataset?.postsToShow ?? blockEl.dataset?.postsToShow,
      6
    );
    const first = Math.min(want, 12);

    fetchPosts(first)
      .then((posts) => renderCards(root, posts))
      .catch((err) => {
        console.warn("[LPG] render failed:", err);
        root.innerHTML =
          '<p class="lpg-error">Could not load posts right now.</p>';
      });
  }

  function initAll() {
    document
      .querySelectorAll(".wp-block-lpg-latest-posts-grid")
      .forEach(initOne);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initAll);
  } else {
    initAll();
  }
})();
