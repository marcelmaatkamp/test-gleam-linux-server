FROM ghcr.io/gleam-lang/gleam:v1.7.0-elixir-slim AS build
COPY application /app/
RUN mix local.hex --force
RUN cd /app && gleam export erlang-shipment

FROM erlang:27.1.1.0-alpine
RUN \
  addgroup --system webapp && \
  adduser --system webapp -g webapp
COPY --from=build /app/build/erlang-shipment /app
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]