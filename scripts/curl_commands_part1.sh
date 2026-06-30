# No relations in the response (the default).
curl 'http://localhost:1337/api/articles'

# `populate=category` brings the category relation back for every article.
curl 'http://localhost:1337/api/articles?populate=category'

# `fields` restricts which scalar attributes are returned.
curl 'http://localhost:1337/api/articles?populate=category&fields[0]=title'