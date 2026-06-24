# Bare query, no filter: succeeds, archived rows absent
curl -s -X POST http://localhost:1337/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ notes { title archived } }"}'
# -> {"data":{"notes":[{"title":"...","archived":false}, ...]}}

# Sneaky query, archived: true: rejected
curl -s -X POST http://localhost:1337/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ notes(filters:{ archived:{ eq: true } }){ title } }"}'
# -> {"errors":[{"message":"Cannot filter on `archived` directly. ... ", "extensions":{"code":"FORBIDDEN", ... }}],"data":null}

# Polite query, archived: false: also rejected. The server alone manages archived.
curl -s -X POST http://localhost:1337/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ notes(filters:{ archived:{ eq: false } }){ title } }"}'
# -> {"errors":[{"message":"Cannot filter on `archived` directly. ... ", "extensions":{"code":"FORBIDDEN", ... }}],"data":null}


################################################################################

# pageSize over the cap: Policy Failed
curl -s -X POST http://localhost:1337/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ notes(pagination:{ pageSize: 500 }){ documentId } }"}'
# -> {"errors":[{"message":"Policy Failed", ... }],"data":null}

# pageSize inside the cap: 200 OK
curl -s -X POST http://localhost:1337/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ notes(pagination:{ pageSize: 10 }){ documentId } }"}'
# -> {"data":{"notes":[ ... ]}}

################################################################################

# Direct fetch of an archived note: rejected with NotFound
curl -s -X POST http://localhost:1337/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"query F($id: ID!){ note(documentId: $id){ documentId title archived } }","variables":{"id":"ax0wugxqcvuehtjq0ja7l4qt"}}'
# -> {"errors":[{"message":"Note not found.", "extensions":{"code":"STRAPI_NOT_FOUND_ERROR", ... }}],"data":{"note":null}}

# Direct fetch of an active note: 200 OK
curl -s -X POST http://localhost:1337/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"query F($id: ID!){ note(documentId: $id){ documentId title } }","variables":{"id":"ax0wugxqcvuehtjq0ja7l4qt"}}'
# -> {"data":{"note":{"documentId":"...","title":"..."}}}

################################################################################

# GraphQL: the middleware blocks the archived filter
curl -s -X POST http://localhost:1337/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ notes(filters:{ archived:{ eq: true } }){ title archived } }"}'
# -> {"errors":[{"message":"Cannot filter on `archived` directly. ... ",
#                "extensions":{"code":"FORBIDDEN", ... }}],"data":null}

# REST: nothing blocks it, archived rows come back
curl -s "http://localhost:1337/api/notes?filters\[archived\]\[\$eq\]=true"
# -> {"data":[ ... archived notes here ... ],"meta":{ ... }}
