# Web deployment (GCP Cloud Run)

The Flutter web build is deployed to **Google Cloud Run** as a static site served by nginx. The workflow follows the same pattern as [tripod-backend](https://github.com/shemaobt/tripod-backend) (Artifact Registry + Cloud Run).

## CI workflow (merge to main)

The workflow [.github/workflows/deploy-web.yml](../.github/workflows/deploy-web.yml) runs **on push to `main`** and on manual trigger (`workflow_dispatch`). It:

1. Builds the Flutter web app (`flutter build web --release`).
2. Builds a Docker image (nginx serving `build/web`) and pushes it to **Artifact Registry**.
3. Deploys the image to **Cloud Run** as the service `oral-collector-web`.

Required GitHub secrets (Settings → Secrets and variables → Actions):

| Secret | Purpose |
|--------|---------|
| `GCP_PROJECT_ID` | GCP project ID for Artifact Registry and Cloud Run |
| `GCP_SA_KEY` | Service account key JSON with roles: Cloud Run Admin, Artifact Registry Writer (and optionally Secret Manager if you add secrets later) |

You can reuse the same project and service account as other Shema apps (e.g. tripod-backend) if they already have these secrets in the org or in this repo.

## Discovering GCP config (gcloud CLI)

To see the project and account used by your local `gcloud`:

```bash
gcloud config get-value project   # → use as GCP_PROJECT_ID
gcloud config get-value account   # → your identity (not needed as a secret)
```

Set `GCP_PROJECT_ID` in GitHub Actions secrets to the project where you want Cloud Run and Artifact Registry (e.g. `gen-lang-client-0886209230` if using the same project as other Shema apps).

## One-time GCP setup

1. **Artifact Registry repository** — The `oral-collector` repo has been created in `us-central1`. If you use a different project, create it with:

   ```bash
   gcloud artifacts repositories create oral-collector \
     --repository-format=docker \
     --location=us-central1 \
     --project=$(gcloud config get-value project)
   ```

2. **Service account** used by `GCP_SA_KEY` must have:
   - **Cloud Run Admin** (to deploy)
   - **Artifact Registry Writer** (to push images)
   - **Service Account User** (to deploy as the runtime SA) if needed

3. **Enable APIs** (if not already):
   - Artifact Registry API
   - Cloud Run Admin API

## Local build and run (Docker)

To test the same image locally:

```bash
flutter build web --release
docker build -f docker/Dockerfile.web -t oral-collector-web:local .
docker run -p 8080:8080 oral-collector-web:local
```

Open http://localhost:8080

## Manual deploy

From the repo root, with `gcloud` and Docker configured:

```bash
flutter build web --release
docker build -f docker/Dockerfile.web -t us-central1-docker.pkg.dev/YOUR_PROJECT_ID/oral-collector/web:manual .
docker push us-central1-docker.pkg.dev/YOUR_PROJECT_ID/oral-collector/web:manual
gcloud run deploy oral-collector-web \
  --image us-central1-docker.pkg.dev/YOUR_PROJECT_ID/oral-collector/web:manual \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated
```

Replace `YOUR_PROJECT_ID` with your `GCP_PROJECT_ID`, or run `gcloud config get-value project` to use the current default.
