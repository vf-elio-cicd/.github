FROM library/node:18-bookworm-slim AS base

WORKDIR /app/
COPY ./package.json /app/.
COPY ./package-lock.json /app/.
RUN npm ci --omit=dev

FROM base AS builder

WORKDIR /app/

COPY . /app/
RUN npm ci && npm run build && npm run package

FROM gcr.io/distroless/nodejs18-debian12 AS final

WORKDIR /app/

COPY --from=base /app/. /app/.
COPY --from=builder /app/src/. /app/src/.
COPY --from=builder /app/dist/. /app/dist/.

EXPOSE 3000/TCP

CMD [ "/app/dist/index.js" ]
