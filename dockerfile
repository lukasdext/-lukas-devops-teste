# Definindo a Imagem base.
FROM node:12.18.3-alpine3.12

COPY ./ ./

WORKDIR /app

EXPOSE 3000

RUN npm install

# Executando aplicacão no Container.
CMD ["npm", "start"]