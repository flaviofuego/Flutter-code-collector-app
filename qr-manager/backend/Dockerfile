FROM node:20

WORKDIR /app

# Copiar package.json y package-lock.json primero para aprovechar cache de Docker
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar el resto del código
COPY . .

EXPOSE 8000

CMD ["npm", "run", "dev"]
