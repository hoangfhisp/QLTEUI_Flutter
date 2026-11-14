# RESTful API & DTO Specifications

## 1. Overview

The client communicates with the backend REST gateway using standard JSON payloads over HTTPS. Base URLs and fallback addresses are dynamically configured via `.env` files using `Config_URL`.

All authenticated requests include the Bearer token in the HTTP `Authorization` header:
```http
Authorization: Bearer <access_token>
```

---

## 2. API Endpoints Catalog

### 2.1 Authentication & Profile (`/api/auth`, `/api/user`)
- `POST /api/auth/login`: Authenticate with email/password; returns access token, refresh token, role, and expiration.
- `POST /api/auth/google-login`: External OAuth2 exchange sending Google `idToken`.
- `POST /api/auth/refresh-token`: Silent token refresh prior to access token expiry.
- `POST /api/auth/forgot-password`: Initiate password recovery workflow.
- `GET /api/user/profile`: Retrieve profile information for the authenticated identity.
- `PUT /api/user/profile`: Update contact info and personal metadata.

### 2.2 Child Management (`/api/child`)
- `GET /api/child/parent/{parentId}`: Fetch all children bound to a parent account.
- `POST /api/child/create`: Register a new child profile.
- `GET /api/child/{id}`: Detailed child telemetry, linked device status, and active restrictions.

### 2.3 Geofencing & Location History (`/api/safezone`, `/api/dangerzone`, `/api/location`)
- `GET /api/safezone/child/{childId}`: List active safe zones (home, school).
- `POST /api/safezone/create`: Define perimeter center coordinates and radius in meters.
- `GET /api/dangerzone/child/{childId}`: List flagged caution perimeters.
- `GET /api/location/history/{childId}`: Retrieve historical breadcrumb points for route playback.

### 2.4 Device Controls & Restrictions (`/api/devicerestriction`, `/api/device`)
- `GET /api/devicerestriction/{deviceId}`: Fetch blocked package names and schedule locks.
- `PUT /api/devicerestriction/update`: Apply updated restrictions or toggle the global firewall.
- `POST /api/device/telemetry`: Push battery health, connectivity type, and OS versions.

### 2.5 Academic Scheduling (`/api/schedule`, `/api/examschedule`, `/api/studyperiod`)
- `GET /api/studyperiod/child/{childId}`: Retrieve active study periods.
- `POST /api/studyperiod/create`: Add a new recurring study window.
- `GET /api/schedule/child/{childId}`: Daily class timetable.
- `GET /api/examschedule/child/{childId}`: Upcoming examinations and details.

### 2.6 Emergency SOS (`/api/sos`)
- `POST /api/sos/create`: Submit an emergency report with coordinates.
- `GET /api/sos/active`: Fetch unacknowledged emergencies for the parent dashboard.
- `PUT /api/sos/{id}/resolve`: Mark an emergency as safe or handled.

---

## 3. Data Transfer Objects (DTOs)

### Authentication Response Model
```json
{
  "accessToken": "eyJhbGciOi...",
  "refreshToken": "d8f1e2c3...",
  "role": "Parent",
  "userId": "guid-here",
  "expiresIn": 3600
}
```

### SOS Request Model
```json
{
  "id": "guid-here",
  "childId": "guid-child",
  "latitude": 10.7769,
  "longitude": 106.7009,
  "status": "Active",
  "note": "Urgent assistance requested",
  "createdAt": "2026-11-14T11:15:00Z"
}
```
