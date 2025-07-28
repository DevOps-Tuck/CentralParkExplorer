# 🌳 Central Park Explorer

Welcome to **Central Park Explorer** — a beautifully interactive iOS app that tracks your walking progress through Central Park using a live map, trail history, and celebratory milestone badges. Explore the park, tile by tile, and uncover achievements as you go.

---

## 🚀 Features

- 🗺️ **Live Map**: Track your real-time location and progress with trail overlays.
- 🧩 **Hex Tile Exploration**: Unique hexagonal tiling marks explored zones as you walk.
- 📍 **Exploration Tracking**: Accurate % progress displayed live on-screen.
- 🎉 **Celebration Toasts**: Milestone achievements at 10%, 25%, 50%, 75%, and 100%.
- 🏅 **Badge System**: Earn and view badges when you reach each milestone.
- ✨ **Confetti Animation**: Celebrate key achievements with on-screen effects.
- 🧭 **Inside Boundary Only**: Exploration only counts inside the real Central Park border.
- 🔙 **Back Button**: Navigate back to the welcome screen and badge view without losing your progress.

---

## 📦 Installation (Local Dev)

1. **Clone the repo:**


```
git clone https://github.com/DevOps-Tuck/CentralParkExplorer.git
cd CentralParkExplorer
```
## open CentralParkExplorer.xcodeproj
- Run the project on an iOS simulator or real device.
- GPX Simulation (Optional):
- Use one of the provided GPX files to simulate walking routes in Xcode.
- Choose a GPX file from the project folder and run it via the simulator’s “Features > Location > Custom Location” option.

⸻

## 🛠 Project Structure
- ViewController.swift
— Main map UI with tile logic and toast rendering.
- IntroViewController.swift — Welcome screen with badge icons and start button.
- Badge.swift — Milestone tracking and display logic.
- CentralParkFullWalk.gpx — Full route simulation inside Central Park.


⸻

Milestone
Badges
Toast Message
10%
🛡️
“10% Explored! You’re just getting started 🎉”
25%
🛡️
“25% Explored! Great progress!”
50%
🛡️
“Halfway there! 50% complete 🎉”
75%
🛡️
“75%! Almost there 💪”
100%
🏁
“You’ve explored all of Central Park! Incredible work!”


Developer:

Built with ❤️ by @yalenorman
Inspired by exploration, cartography, and Central Park itself 💚
