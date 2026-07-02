# ---- ABC Technologies Corporate Website ----
# Lightweight nginx image serving the static site
FROM nginx:alpine

# Remove default nginx welcome page
RUN rm -rf /usr/share/nginx/html/*

# Copy website files into nginx's web root
COPY website/ /usr/share/nginx/html/

# Optional: custom nginx config (kept default here for simplicity)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD wget -qO- http://localhost/health.txt || exit 1

CMD ["nginx", "-g", "daemon off;"]
