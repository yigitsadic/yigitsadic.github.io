FROM jekyll/jekyll

WORKDIR /srv/jekyll

COPY Gemfile Gemfile*.lock ./

RUN bundle install

COPY . .

CMD [ "bundle", "exec", "jekyll", "serve", "--force_polling", "-H", "0.0.0.0", "-P", "4000" ]
