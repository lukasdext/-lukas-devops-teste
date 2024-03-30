FROM node:alpine

WORKDIR /usr/app

COPY . /usr/app

EXPOSE 3000

CMD ["npm", "run", "start"]