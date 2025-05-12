# REMEDY – Smart Medication Reminder App

A mobile application that helps users stay on track with their medications by sending timely reminders and tracking dose history.

---
## Features

- Sends medication reminders based on the user's custom schedule.
- Allows users to confirm taken doses with a single tap.
- Supports multiple medication schedules: daily, weekly, or specific days.
- Alerts users when their medication supply is running low.
- Keeps a log of all taken and missed doses for personal tracking.

---

## Limitations

- Manual schedule setup required
- Users must confirm doses manually
- No built-in medication ordering

---

## Tech Stack

- SwiftUI (UI & architecture)
- Firebase Firestore (Data storage)
- Firebase Auth (Authentication)
- UserNotifications (Local alerts)
- MVVM Architecture (Modular, Clean design)

---

## Getting Started

1. Clone the project
```bash
git clone https://github.com/Pichayanon/REMEDY 
```

2. Open the project in Xcode
  - Requires Xcode 14 or later
  - Open `REMEDY.xcodeproj`

3. Set up Firebase

- Go to https://console.firebase.google.com/
- Create a new project
- Enable Firestore and Email/Password Authentication
- Download `GoogleService-Info.plist`
- Add it to the Xcode project (`REMEDY/REMEDY` directory)

4. Run the app

- Build and run the project on simulator or device
- Allow notifications when prompted

---
## Project Structure

| Path                        | Description                                                                      |
| :-------------------------- | :------------------------------------------------------------------------------- |
| `/App/`                     | App entry point and lifecycle                                                    |
| `/ViewModels/`              | Business logic                                                                   |
| `/Models/`                  | Data models                                                                      |
| `/Views/`                   | SwiftUI views                                                                    |
| `/Assets.xcassets/`         | App icons, accent colors, and UI assets                                          |
| `/GoogleService-Info.plist` | Firebase configuration file                                                      |
| `README.md`                 | Project documentation and setup guide                                            |

---

## Team

- Pichayanon Toojinda (6510545624)  
- Yasatsawin Kuldejtitipun (6510545705)

---
