FROM node:9

WORKDIR /app

COPY package.json .
RUN npm install

COPY . .

USER node
EXPOSE 8080

CMD ["npm", "run", "start:dev","--","--port","8080"]
