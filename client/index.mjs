// Node 18+ has fetch built-in
const endpoint = process.env.WP_GRAPHQL_URL ?? 'http://localhost:8080/graphql';

const QUERY = `
  query($first:Int!){
    posts(first:$first, where:{orderby:{field:DATE, order:DESC}}){
      nodes { databaseId title uri date }
    }
  }
`;

async function main() {
  const res = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query: QUERY, variables: { first: 4 } })
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const json = await res.json();
  if (json.errors) throw new Error(JSON.stringify(json.errors, null, 2));

  for (const p of json.data.posts.nodes) {
    console.log(`${p.databaseId}: ${p.title}  ${p.uri}`);
  }
}

main().catch(err => {
  console.error('GraphQL error:', err.message);
  process.exit(1);
});
