FROM ghcr.io/gleam-lang/gleam:v1.8.1-elixir AS build
# COPY --from=ghcr.io/gleam-lang/gleam:v1.8.1-erlang-alpine /bin/gleam /bin/gleam
COPY application /app/
RUN mix local.hex --force
RUN cd /app && gleam export erlang-shipment

FROM erlang:27.2.3.0-alpine
RUN \
  addgroup --system webapp && \
  adduser --system webapp -g webapp
COPY --from=build /app/build/erlang-shipment /app
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]