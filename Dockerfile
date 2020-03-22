FROM elixir:1.10.2-alpine

ARG MIX_ENV=dev

RUN echo "Building Spot-On for MIX_ENV - $MIX_ENV"
ENV MIX_ENV=$MIX_ENV

# Required for pg_isready
RUN apk --update add postgresql-client

RUN mkdir /app
COPY . /app
WORKDIR /app

RUN mix local.hex --force
RUN MIX_ENV=$MIX_ENV mix do compile

CMD ["/app/docker-entrypoint.sh"]
