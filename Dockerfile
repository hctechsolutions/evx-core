# Use a lightweight Nginx image to serve static files
FROM nginx:alpine

# Define the directory where the documentation está located
ARG DOCS_DIR=docs/book

# Copy the documentation para dentro de /usr/share/nginx/html/book/
COPY ${DOCS_DIR} /usr/share/nginx/html/book/

# Expose port 80 to serve the documentation
EXPOSE 80

# Default command to run Nginx
CMD ["nginx", "-g", "daemon off;"]