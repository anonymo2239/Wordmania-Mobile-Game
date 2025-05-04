# WordMania Mobile Game

**WordMania** is a real-time, multiplayer word-based mobile game developed for the **Software Laboratory II** course at Kocaeli University. Players take turns forming valid words on a shared board, encountering hidden traps (mines) and rewards that affect gameplay and scoring. The game emphasizes both linguistic skill and strategic thinking under time constraints.

## Game Features

- **Real-time multiplayer gameplay using Firebase**
- **15x15 dynamic board** with score multipliers (H², K³, etc.)
- **Hidden traps and rewards:**
  - *Mines*: Point Split, Point Transfer, Letter Loss, etc.
  - *Bonuses*: Extra Move, Letter Freeze, Region Lock
- **Word validation system** using a Turkish dictionary
- **Multiple time modes:** 2 min, 5 min, 12 hours, 24 hours
- **User statistics tracking:** win rate, total games, total wins

## Screenshots

- Login & Registration
- Main menu and match history
- Game board with mine logic
- Result dialog (win/lose/tie)

## Technologies Used

| Technology      | Purpose                              |
|-----------------|--------------------------------------|
| **Flutter**     | Cross-platform UI and development    |
| **Firebase**    | Realtime database and authentication |
| **Cloud Firestore** | Game state sync and user data   |
| **Dart**        | Main programming language            |

## Game Mechanics

### Letter Distribution & Scoring
- Players start with 7 random letters.
- Each letter has a score based on its frequency in Turkish.

### Score Multipliers
- The board contains special tiles such as:
  - `H²` (Double Letter)
  - `K³` (Triple Word)

### Mines (Penalties)
| Type               | Effect                                                              |
|--------------------|---------------------------------------------------------------------|
| Point Split        | Player receives only 30% of total word score                        |
| Point Transfer     | Full score is transferred to the opponent                           |
| Letter Loss        | All current letters are lost and new ones are drawn                 |
| Extra Move Blocker | Score multipliers on tiles are disabled for this turn               |
| Word Cancel        | No points awarded even for valid words                              |

### Bonuses (Rewards)
| Type                | Effect                                                              |
|---------------------|---------------------------------------------------------------------|
| Region Lock         | Opponent is restricted to one side of the board                    |
| Letter Freeze       | 2 of opponent's letters become unusable for 1 turn                  |
| Extra Move Joker    | Allows the player to play a second word without changing turns      |

## Game Flow

1. User logs in or registers.
2. Chooses a time mode (2min/5min/12h/24h).
3. Players are matched and the game begins.
4. Each player forms valid words, and traps/rewards are triggered as needed.
5. When no letters remain or time runs out, the winner is determined.

## Client-Server Architecture

- Firebase Firestore is used for **real-time sync** between players.
- Authentication via Firebase Auth.
- Game states, boards, and scores update dynamically for both players.

## Setup

```bash
flutter pub get
flutter run
```

Make sure you configure your Firebase project and include the `google-services.json` in the `android/app` directory.

## Developers

- **Alperen Arda** – [alperen.arda.adem22@gmail.com](mailto:alperen.arda.adem22@gmail.com)
- **Ömer Şimşek** – [omer2020084@gmail.com](mailto:omer2020084@gmail.com)
