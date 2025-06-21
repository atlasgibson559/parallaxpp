# Parallax.Relay

`Parallax.Relay` is a secure value sync system built around [SFS](https://github.com/Srlion/sfs). It lets you transmit values safely between server and clients across three scopes: global, per-player, and per-entity.

---

## 🔧 Scopes

### Shared (Global)

```lua
-- SERVER
Parallax.Relay:SetShared("weather", "storm")

-- CLIENT
print(Parallax.Relay:GetShared("weather", "clear")) -- Outputs: storm
```

---

### User (Per-Player)

```lua
-- SERVER
player:SetUser("reputation", 120)

-- CLIENT
local rep = LocalPlayer():GetUser("reputation", 0)
print(rep) -- Outputs: 120
```

---

### Entity (Per-Entity)

```lua
-- SERVER
door:SetEntity("locked", true)

-- CLIENT
print(someDoor:GetEntity("locked", false)) -- Outputs: true if synced
```

---

## 🌐 Internals

- Uses net messages:
  - `Parallax.Relay.shared`
  - `Parallax.Relay.user`
  - `Parallax.Relay.entity`
- Data is serialized, compressed, and encrypted via [SFS](https://github.com/Srlion/sfs).

---

## Notes

- Only the **server** can send values.
- Clients automatically receive and unpack via net messages.
- Useful for syncing state like doors, character traits, reputation, or shared variables.

---

## API

- `SetShared(key, value, recipient)`
- `GetShared(key, default)`
- `Player:SetUser(key, value, recipient)`
- `Player:GetUser(key, default)`
- `Entity:SetEntity(key, value, recipient)`
- `Entity:GetEntity(key, default)`
