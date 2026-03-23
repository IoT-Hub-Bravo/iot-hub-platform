FROM nginx:alpine

# Copy nginx.conf to the main config
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf

# Create directory for certificates
RUN mkdir -p /etc/nginx/certs

# Expose HTTPS port
EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]