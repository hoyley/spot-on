FROM elixir:latest

# Required for pg_isready
RUN apt-get update && \
  apt-get install -y postgresql-client

RUN mkdir /app
COPY . /app
WORKDIR /app

RUN mix local.hex --force
RUN mix do compile

CMD ["/app/docker-entrypoint.sh"]