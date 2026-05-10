FROM node:22-alpine AS build

WORKDIR /app
COPY angular/G-rez-l-int-gration-et-la-livraison-continue-Application-Angular/package*.json ./
RUN npm ci
COPY angular/G-rez-l-int-gration-et-la-livraison-continue-Application-Angular/ ./
RUN npm run build -- --configuration production

FROM nginx:1.27-alpine

COPY --from=build /app/dist/olympic-games-starter/browser/ /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
