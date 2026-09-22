FROM barichello/godot-ci:4.3 AS build
WORKDIR /app
COPY . .
RUN mkdir -p build/web && godot --headless --export-release "Web" build/web/index.html

FROM node:20-alpine
WORKDIR /srv
COPY package.json server.js ./
RUN npm install --omit=dev
COPY --from=build /app/build/web ./public
ENV PORT=8080
EXPOSE 8080
CMD ["node","server.js"]
