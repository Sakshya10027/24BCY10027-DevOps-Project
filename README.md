# ABC Technologies — Corporate Website DevOps Project
### Use Case 1: Corporate Company Website Deployment

This project contains a static corporate website (Home, About Us, Services,
Careers, Gallery, Contact Us) plus a full DevOps pipeline: Git → Jenkins →
Docker → Kubernetes → Nagios → Graphite → Grafana.

Everything below is a **copy-paste-able runbook**. Follow it top to bottom,
taking the screenshot noted at the end of each step. At the very end there's
a checklist mapping each screenshot to a submission requirement.

---

## 0. Prerequisites

Install these on your machine (Windows/Linux/Mac all work — use WSL2 on
Windows for smoothest results):

- Git
- Docker Desktop (includes Docker Engine)
- A Kubernetes cluster — easiest is **Minikube** (or enable Kubernetes in
  Docker Desktop)
- `kubectl` CLI
- Jenkins (run it as a Docker container — see Step 2)
- Nagios Core (run via Docker image `jasonrivers/nagios` — easiest route)
- Graphite (run via Docker image `graphiteapp/graphite-statsd`)
- Grafana (run via Docker image `grafana/grafana`)
- A free Docker Hub account
- A free GitHub account

---

## 1. Git & GitHub

```bash
cd project
git init
git add .
git commit -m "Initial commit: ABC Technologies website + DevOps pipeline"
git branch -M main
git remote add origin https://github.com/Sakshya10027/24BCY10027-DevOps-Project.git
git push -u origin main
```

📸 **Screenshot:** GitHub repo page showing all files pushed.
✅ Gives you **Mandatory Link #1 (GitHub Repository)**.

If a friend/teammate also commits (to satisfy "multiple developers
collaborate"), have them clone the repo, make a small edit (e.g. tweak a
line in `about.html`), commit, and push. Screenshot the commit history
showing 2 different authors.

---

## 2. Run Jenkins

```bash
docker run -d --name jenkins \
  -p 8081:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

- Open `http://localhost:8081`
- Unlock Jenkins: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
- Install suggested plugins, plus: **Docker Pipeline**, **Kubernetes CLI**, **GitHub Integration**
- Create admin user

### Add credentials
Manage Jenkins → Credentials → Add:
- `dockerhub-creds` — your Docker Hub username/password (matches the ID
  used in the `Jenkinsfile`)

### Create the pipeline job
- New Item → Pipeline → name it `abc-website-pipeline`
- Pipeline → Definition: "Pipeline script from SCM" → Git → paste your repo
  URL → Script Path: `Jenkinsfile`
- Save → **Build Now**

📸 **Screenshots:** Jenkins Dashboard, Job Configuration page, Console
Output (full green log), and the "Build Success" page.
✅ Satisfies **Mandatory Link #2** (or the required screenshots if local).

> Note: since Jenkins runs in a container, it needs Docker CLI access — the
> `-v /var/run/docker.sock:/var/run/docker.sock` mount above gives it that.
> You'll also need to install `docker` and `kubectl` binaries inside the
> Jenkins container, or use a Jenkins agent image that already has them
> (e.g. build a custom Jenkins image with those tools installed).

---

## 3. Docker

Even outside Jenkins, verify it builds locally first:

```bash
cd project
docker build -t abc-technologies-website:latest .
docker run -d --name abc-website -p 8080:80 abc-technologies-website:latest
```

Visit `http://localhost:8080` in your browser.

📸 **Screenshots:**
- `docker build` terminal output (image built successfully)
- `docker ps` showing the container running
- Browser showing the live website

Push to Docker Hub:
```bash
docker login
docker tag abc-technologies-website:latest <your-dockerhub-username>/abc-technologies-website:latest
docker push <your-dockerhub-username>/abc-technologies-website:latest
```
✅ Gives you **Mandatory Link #3 (Docker Hub Repository, optional)**.

---

## 4. Kubernetes

Before applying manifests, edit `k8s/deployment.yaml` and replace
`YOUR_DOCKERHUB_USERNAME` with your actual Docker Hub username.

```bash
minikube start          # if using minikube
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl get pods
kubectl get svc abc-website-service
```

Access the app:
```bash
minikube service abc-website-service --url
# or, if using Docker Desktop's built-in Kubernetes:
# http://localhost:30080
```

📸 **Screenshots:** `kubectl get pods` (Running state), `kubectl get svc`
(NodePort assigned), and the browser showing the app via the K8s service URL.
✅ Gives you **Mandatory Link #4 (Application URL)**.

---

## 5. Nagios

Easiest path — run Nagios in Docker:

```bash
docker run -d --name nagios \
  -p 8082:80 \
  -e NAGIOSADMIN_USER=admin \
  -e NAGIOSADMIN_PASS=admin123 \
  jasonrivers/nagios:latest
```

Copy the provided config in so Nagios watches your website:
```bash
docker cp nagios/abc-website.cfg nagios:/opt/nagios/etc/objects/abc-website.cfg
```
Then edit `/opt/nagios/etc/nagios.cfg` inside the container to add:
```
cfg_file=/opt/nagios/etc/objects/abc-website.cfg
```
Also edit `nagios/abc-website.cfg` and set `address` to your actual host
running the website container (e.g. your machine's LAN IP, since Nagios is
in its own container).

Restart Nagios:
```bash
docker exec nagios service nagios restart
```

Open `http://localhost:8082/nagios` (login admin/admin123).

📸 **Screenshot:** Nagios web UI showing the Host as **UP** (green) and the
HTTP service as **OK** (green).
✅ Gives you **Mandatory Item #6 (Nagios Monitoring Screenshot)**.

---

## 6. Graphite

```bash
docker run -d --name graphite \
  -p 8083:80 -p 2003-2004:2003-2004 -p 2023-2024:2023-2024 -p 8125:8125/udp \
  graphiteapp/graphite-statsd
```

Send it some sample metrics using the provided script:
```bash
chmod +x monitoring/push-metrics-to-graphite.sh
# run it a few times (or loop it) so there's a visible trend
for i in {1..20}; do ./monitoring/push-metrics-to-graphite.sh localhost 2003; sleep 5; done
```

Open `http://localhost:8083` → Graphite Composer → browse Metrics →
`abc_website` → select `cpu.usage_percent`, `memory.usage_mb`,
`http.available` → Add to graph.

📸 **Screenshot:** Graphite Composer showing the plotted metrics.
✅ Gives you **Mandatory Item #7 (Graphite Metrics Screenshot)**.

---

## 7. Grafana

```bash
docker run -d --name grafana -p 3000:3000 grafana/grafana
```

- Open `http://localhost:3000` (login admin/admin, set a new password)
- Connections → Data Sources → Add → **Graphite** → URL: `http://<your-host-ip>:8083` → Save & Test
- Create a new Dashboard → Add Panel → for each panel, query one of:
  - `abc_website.cpu.usage_percent` (CPU Usage)
  - `abc_website.memory.usage_mb` (Memory Usage)
  - `abc_website.http.available` (HTTP Availability)
- Add a 4th panel for **Uptime** — you can derive it from the
  `http.available` series (percentage of time = 1) or add a simple "Stat"
  panel that just shows the current value.
- Save the dashboard as "ABC Technologies Website Monitoring"

📸 **Screenshot:** Full Grafana dashboard showing CPU, Memory, HTTP
Availability, and Uptime panels.
✅ Gives you **Mandatory Item #5 (Grafana Dashboard Screenshot)**.

---

## 8. Final Packaging

```bash
cd ..
zip -r <RegisterNumber>_<Name>_DevOps_Project.zip project/
```

Write your documentation report (use the docx template also provided) with:
- All 7 mandatory links/screenshots at the top
- Step-by-step screenshots for every section above, in order
- The final checklist from the assignment, all boxes ticked

---

## Troubleshooting tips

- **Jenkins can't run `docker` or `kubectl`:** build a custom Jenkins image
  (`FROM jenkins/jenkins:lts` + `RUN apt-get install docker.io` and copy in
  the `kubectl` binary), or install them manually inside the running
  container with `docker exec -it jenkins bash`.
- **Nagios can't reach the website container:** they need to be on a
  network that can see each other. Easiest fix: put both containers on the
  same custom Docker network (`docker network create devops-net`, then
  `--network devops-net` on each `docker run`), and use the container name
  as the address instead of an IP.
- **Kubernetes service not reachable:** if using Docker Desktop's
  Kubernetes (not Minikube), NodePort services are reachable directly at
  `localhost:<nodePort>`. If using Minikube, always use
  `minikube service <name> --url` to get the correct URL.
