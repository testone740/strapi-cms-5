# 1. Public role: Forbidden
curl -s -X POST http://localhost:1337/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ notes { documentId title } }"}'
# -> {"errors":[{"message":"Forbidden access", ... }],"data":null}

# 2. Register testuser
curl -s -X POST http://localhost:1337/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"mutation R($input: UsersPermissionsRegisterInput!) { register(input: $input) { jwt user { username email } } }","variables":{"input":{"username":"testuser","email":"testuser@example.com","password":"testuser"}}}'
# -> {"data":{"register":{"jwt":"<JWT>", ... }}}

# 3. Signed-in read: every note in the database
JWT="<paste-the-token>"
curl -s -X POST http://localhost:1337/graphql \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $JWT" \
  -d '{"query":"{ notes { documentId title } }"}'
# -> {"data":{"notes":[ ... every note in the database ... ]}}
