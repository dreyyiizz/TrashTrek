# 🗑️ TrashTrek

![TrashTrek Logo](credits/GameTitle.png)

**TrashTrek** is a fast-paced endless runner and sorting game built with Godot 4.4. Take on the role of an eco-warrior running through a changing landscape, collecting trash, and ensuring it gets sorted into the correct bins to save the environment!

## 🎮 Gameplay

In **TrashTrek**, your goal is to run as far as possible while managing your energy and cleaning up the world.

- **Collect Trash**: Run into trash items scattered across the terrain.
- **Sort Correctly**: Switch between trash types to match the bins you encounter.
- **Manage Energy**: Your energy depletes over time. Collecting and correctly sorting trash helps replenish it.
- **Avoid Hazards**: Watch out for monsters that will hurt you and drain your energy!
- **Upgrade**: Use your collected points in the shop to upgrade your energy capacity and gain more from each piece of trash.

## ⌨️ Controls

| Action                   | Key / Input                  |
| :----------------------- | :--------------------------- |
| **Jump**                 | `Space` / `Left Mouse Click` |
| **Move Left**            | `A` / `Left Arrow`           |
| **Move Right**           | `D` / `Right Arrow`          |
| **Select Recyclable**    | `Z`                          |
| **Select Biodegradable** | `X`                          |
| **Select Toxic Waste**   | `C`                          |
| **Pause**                | `Esc`                        |

## 🚀 Features

- **Endless Runner**: Procedurally generated terrain that gets harder the further you go.
- **Sorting Mechanic**: Three types of trash (Biodegradable, Recyclable, Toxic Waste) requiring quick reflexes to sort.
- **Shop System**: Purchase upgrades and skins to improve your performance.
- **Leaderboards**: Compete with other players for the highest score and longest distance.
- **Dynamic Difficulty**: The game speeds up and energy drains faster as you progress.

## 🛠️ Technical Details

- **Engine**: [Godot Engine 4.4](https://godotengine.org/)
- **Language**: GDScript
- **Architecture**: State-machine based player controller, global game manager, and modular UI system.

## ⚙️ Local Setup

To run this project locally, follow these steps:

### Prerequisites

- Download and install **[Godot Engine 4.4](https://godotengine.org/download)** (Forward Plus renderer recommended).

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/dreyyiizz/GameOn.git
   ```
2. **Set up Environment Variables**:
   Create a `.env` file in the root directory and add your server.

   Note: The server is found in another repository. [Click here to access it.](https://github.com/wends05/trashtrek-server.git)
   
   URL:

   ```env
   SERVER_URL="your_api_server_url_here"
   ```

3. **Open Godot Engine**.
4. Click on **Import** and navigate to the cloned folder.
5. Select the `project.godot` file and click **Open**.
6. Once the project loads, press `F5` or the **Play** button in the top right corner to start the game.

## 👥 Credits

### Lead Developer

- **Wendell Terence Dador**

### Developers

- **Vhea Asesor**
- **John Patrick Gerona**
- **Paul Andrei Ardiente**
- **Dainz Andrei Trasadas**

---

_Developed for GameOn 2025._
