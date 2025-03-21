# Use uma imagem leve do Nginx para servir os arquivos estáticos
FROM nginx:alpine

# Defina o diretório onde a documentação está localizada
ARG DOCS_DIR=docs/book

# Copia a documentação para o diretório padrão do Nginx
COPY ${DOCS_DIR} /usr/share/nginx/html

# Exponha a porta 80 para servir a documentação
EXPOSE 8080
EXPOSE 80

# Comando padrão para rodar o Nginx
CMD ["nginx", "-g", "daemon off;"]