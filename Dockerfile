FROM barichello/godot-ci:4.3 AS build
WORKDIR /app
COPY . .
RUN mkdir -p build/web && godot --headless --export-release "Web" build/web/index.html

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
