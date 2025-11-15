+---------------------+            +------------------------+            +-----------------------+
| cemeteries          |            | burials                |            | soldiers              |
+---------------------+            +------------------------+            +-----------------------+
| id                  |◀──┐   ┌───▶| cemetery_id            |            | id                    |
| name                |   │   │    | participant_id         |───────────▶|                       |
| city                |   │   │    | participant_type       |───┐        |                       |
| state               |   │   │    +------------------------+   │        +-----------------------+
| country             |   │   │                                 │
+---------------------+   │   │     "participant_type" column    │
      ▲  has_many :burials│   │     tells Rails what model to use│
      │                   │   │     (e.g., "Soldier")            │
      │                   │   │                                 │
      │                   │   └─────────────────────────────────┘
      │
      │
      └───────────────────────────────────────────────────────────────┐
          has_many :buried_soldiers,
                   through: :burials,
                   source: :participant,
                   source_type: "Soldier"
