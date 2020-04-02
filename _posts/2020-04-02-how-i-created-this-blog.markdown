---
layout: post
title:  "Bu blog'u nasıl oluşturdum?"
date:   2020-04-03 00:07:00 +0300
categories: docker ruby
---

Merhaba, bu yazıda blog'u nasıl oluşturduğumu anlatacağım.

Öncelikle docker hub üzerinden jekyll için arama yaptım ve karşıma şu [image](https://hub.docker.com/r/jekyll/jekyll) çıktı.

Önce blog'u oluşturmak istediğim klasör altına gelip şu komutla jeklyy projesi oluşturdum.

```
$ docker run -v "$(pwd):/app" -it jekyll/jekyll:latest bash
$ cd /app
$ jekyll new my-blog
```

Bu şekilde herhangi bir gem kurulumu vs. uğraşmadan projemi oluşturdum.

Sonraki aşama olarak kendime local dev için dockerignore, Dockerfile ve docker-compose.yml dosyalarımı oluşturdum.

.dockerfile
```
.git
_site
.jekyll-cache
.github
```

Dockerfile
```
FROM jekyll/jekyll

WORKDIR /srv/jekyll

COPY Gemfile Gemfile*.lock ./

RUN bundle install

COPY . .

CMD [ "bundle", "exec", "jekyll", "serve", "--force_polling", "-H", "0.0.0.0", "-P", "4000" ]
```

ve docker-compose.yml

```yaml
version: '3'

services:
  blog:
    build: 
      context: .
    volumes: 
      - .:/srv/jekyll:delegated
    ports: 
      - 4000:4000
```

Bu şekilde `docker-compose up` ile local developmenti rahatça yapabildim.

Github'da <kullanıcı adım>.github.io adı ile public olarak bir repo oluşturup içine bu blog'u attım ve push'ladım.
Github actions default olarak size bir flow öneriyor, ben bunu kullanıp devam ettim.

Görüşmek üzere. À la prochaine !
