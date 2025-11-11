# Deplight
Make Deployment Delightful

## 🚀 Deplight: Real-time DevOps Dashboard (PaaS Simulator)

**Deplight** is a project that simulates a Platform as a Service (PaaS) environment, providing a real-time web dashboard for application deployment, rollback, status management, log streaming, and secret management. It uses a **Flutter Web** frontend, a **Node.js/Socket.io** backend, and is integrated with Firebase/Firestore to offer users a dynamic and realistic DevOps pipeline experience.

-----

## ✨ Features

  * **Multi-Workspace Management:** Users can create and join multiple workspaces, isolating application (Plant) management within each one.
  * **Real-time Deployment & Rollback Simulation:**
      * **GitOps Workflow:** Simulate the deployment of new apps ("Seed Planting") and the rollback of existing ones.
      * **Pipeline Visualization:** Real-time progress display for multi-stage pipelines (e.g., Git Clone, AI Analysis, Docker Build).
      * **Self-Healing Simulation:** On simulated deployment failure, the system transitions to a **FAILED** state, requiring user approval for a rollback.
  * **Live Status Monitoring (Shelf):** Real-time monitoring of all app statuses within a workspace (**HEALTHY**, **DEPLOYING**, **SLEEPING**, **FAILED**).
      * **PaaS Hibernation:** Apps can automatically transition to a **SLEEPING** state after a period of inactivity.
  * **Streaming Logs & Metrics:**
      * **Plant-specific Logs:** Real-time log streaming for deployment and rollback events.
      * **Global System Monitoring:** Live push of global CPU/Memory metrics and aggregated traffic logs to all connected users.
      * **Virtual Console:** Execute simulated commands and receive personalized, streaming console output.
  * **Secret Management:** Create, view (name only), update, and delete environment variables (Secret) at the workspace level. (⚠️ **Note:** Actual value storage in Firestore is used for simulation, but encryption/Secret Managers are required for production.)
  * **Security & Authorization:** **Firebase ID Tokens** secure all Socket.io connections, and access control is enforced based on workspace membership.

-----

## 💻 Tech Stack

| Area | Technology | Role |
| :--- | :--- | :--- |
| **Frontend** | `Flutter Web` | Responsive and dynamic Single Page Application (SPA) UI. |
| **Backend** | `Node.js` (`Express`) | HTTP routing, Slack Webhook handling. |
| **Real-time** | `Socket.io` | Bidirectional, low-latency WebSocket communication. |
| **Database** | `Firebase Firestore` | Persistent storage for all application, workspace, and log data. |
| **Authentication** | `Firebase Admin SDK` | Verifies user ID tokens for secure connections. |
| **Validation** | `Zod` | Ensures strict schema validation for incoming Socket.io payloads. |

-----

## ⚡ Getting Started

### Prerequisites

  * Node.js (LTS recommended)
  * Flutter SDK (with Web support)
  * A configured **Firebase Project** with **Firestore** and **Authentication** enabled.

### Installation & Setup

1.  **Clone the Repository:**

    ```bash
    git clone [Your-Repo-URL]
    cd [repo-name]
    ```

2.  **Firebase Service Account:**

      * Download your Firebase Service Account Key JSON file.
      * Set the environment variable pointing to the key file path.
        ```bash
        # Replace with your actual path
        export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/serviceAccountKey.json"
        ```

    *(Note: This step is skipped when running in a Google Cloud environment like Cloud Run, which uses default application credentials.)*

3.  **Install Dependencies:**

    ```bash
    npm install
    # You will also need to run `flutter pub get` in the separate `frontend` directory.
    ```

### Running the Application

1.  **Build the Frontend (Flutter Web):**
    The backend is configured to serve the build output from the `../frontend/build/web` directory.

    ```bash
    cd ../frontend
    flutter build web
    cd ../backend # Return to the server directory
    ```

2.  **Start the Backend Server:**

    ```bash
    node server.js
    # Or, for development with automatic restart:
    # npm start 
    ```

    The server will be running on the configured port, typically `http://localhost:8080`. Access this URL in your web browser.

-----

## 🗺️ Key Socket.io Events

This table summarizes the core real-time communication between the Frontend and Backend.

| Direction | Event Name | Payload Summary | Description | Target |
| :---: | :--- | :--- | :--- | :--- |
| Client → Server | `join-workspace` | `string` (`workspaceId`) | Authenticates and subscribes the user to the specific workspace's room. | Server |
| Server → Client | `current-shelf` | `Array<Plant Data>` | Pushes the live list of apps in the workspace. | **Room** |
| Client → Server | `start-deploy` | `{ workspaceId, gitUrl, ... }` | Initiates a new application deployment. | Server |
| Server → Client | `pipeline-update` | `{ id, steps, progress, ... }` | Streams real-time deployment pipeline progress. | **Room** |
| Server → Client | `new-log` | `{ id, log: LogData }` | Streams deployment, rollback, and traffic logs. | Individual/All |
| Server → Client | `rollback-required` | `{ id: plantId }` | Signals a deployment failure and requests user intervention. | **Room** |
| Client → Server | `add-secret` | `{ workspaceId, name, value, ... }` | Adds a new environment variable to the workspace. | Server |

-----

## 🤝 Contributing

Contributions are welcome\! Please follow these steps:

1.  Fork the repository.
2.  Create a new feature branch (`git checkout -b feature/awesome-feature`).
3.  Commit your changes (`git commit -m 'Feat: Added an awesome feature'`).
4.  Push to the branch (`git push origin feature/awesome-feature`).
5.  Open a Pull Request.

<!-- end list -->

```
```
